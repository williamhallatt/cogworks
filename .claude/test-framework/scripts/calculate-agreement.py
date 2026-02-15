#!/usr/bin/env python3
"""
Calculate agreement between human and LLM-judge grades.

Usage:
    python3 calculate-agreement.py <human-grades-dir> <llm-results-dir>

Example:
    python3 calculate-agreement.py \
        tests/calibration/human-grades/ \
        tests/results/latest/

Agreement metric: Within 0.5 points on 5-point scale
Target: 90%+ agreement
"""

import sys
import json
import yaml
from pathlib import Path
from typing import Dict, List, Tuple

# Quality categories to compare
CATEGORIES = [
    "source_fidelity",
    "self_sufficiency",
    "completeness",
    "specificity",
    "no_overlap"
]

def load_human_grades(grades_dir: Path) -> Dict[str, Dict]:
    """Load human grades from YAML files."""
    grades = {}

    for yaml_file in grades_dir.glob("*-human.yaml"):
        skill_slug = yaml_file.stem.replace("-human", "")

        with open(yaml_file) as f:
            data = yaml.safe_load(f)

        grades[skill_slug] = data["categories"]

    return grades

def load_llm_grades(results_dir: Path) -> Dict[str, Dict]:
    """Load LLM grades from JSON result files.

    Supports both formats:
    - Legacy: {"categories": {"source_fidelity": {"score": 4}, ...}}
    - Current: {"layer2": {"source_fidelity": {"score": 4}, ...}}
    """
    grades = {}

    for json_file in results_dir.glob("*-results.json"):
        skill_slug = json_file.stem.replace("-results", "")

        with open(json_file) as f:
            data = json.load(f)

        if "layer2" in data:
            grades[skill_slug] = data["layer2"]
        elif "categories" in data:
            grades[skill_slug] = data["categories"]
        else:
            print(f"Warning: Unrecognised format in {json_file}, skipping")
            continue

    return grades

def calculate_category_agreement(
    human_score: float,
    llm_score: float,
    tolerance: float = 0.5
) -> bool:
    """Check if human and LLM scores agree within tolerance."""
    return abs(human_score - llm_score) <= tolerance

def calculate_skill_agreement(
    human_grades: Dict,
    llm_grades: Dict,
    min_categories: int = 4
) -> bool:
    """
    Check if skill grades agree overall.
    Requires agreement in at least 4/5 categories.
    """
    agreements = 0

    for category in CATEGORIES:
        human_score = human_grades.get(category, {}).get("score", 0)
        llm_score = llm_grades.get(category, {}).get("score", 0)

        if calculate_category_agreement(human_score, llm_score):
            agreements += 1

    return agreements >= min_categories

def identify_systematic_biases(
    human_all: Dict[str, Dict],
    llm_all: Dict[str, Dict]
) -> List[Dict]:
    """Identify systematic biases in LLM grading."""
    biases = []

    for category in CATEGORIES:
        diffs = []

        for skill_slug in human_all:
            if skill_slug not in llm_all:
                continue

            human_score = human_all[skill_slug].get(category, {}).get("score", 0)
            llm_score = llm_all[skill_slug].get(category, {}).get("score", 0)

            diffs.append(llm_score - human_score)

        if diffs:
            avg_diff = sum(diffs) / len(diffs)
            over_scored = sum(1 for d in diffs if d > 0.5)
            under_scored = sum(1 for d in diffs if d < -0.5)
            total = len(diffs)

            # Significant bias if >50% of scores consistently off in one direction
            if over_scored / total > 0.5:
                biases.append({
                    "category": category,
                    "bias": "over_scoring",
                    "avg_diff": f"+{avg_diff:.2f}",
                    "frequency": f"{over_scored}/{total} ({over_scored/total*100:.0f}%)"
                })
            elif under_scored / total > 0.5:
                biases.append({
                    "category": category,
                    "bias": "under_scoring",
                    "avg_diff": f"{avg_diff:.2f}",
                    "frequency": f"{under_scored}/{total} ({under_scored/total*100:.0f}%)"
                })

    return biases

def generate_report(
    human_all: Dict[str, Dict],
    llm_all: Dict[str, Dict]
) -> None:
    """Generate calibration report."""
    print("=" * 60)
    print("LLM-Judge Calibration Report")
    print("=" * 60)
    print()

    # Overall agreement
    total_skills = len(set(human_all.keys()) & set(llm_all.keys()))
    agreements = 0

    for skill_slug in human_all:
        if skill_slug not in llm_all:
            continue

        if calculate_skill_agreement(human_all[skill_slug], llm_all[skill_slug]):
            agreements += 1

    agreement_rate = agreements / total_skills if total_skills > 0 else 0

    print(f"Skills evaluated: {total_skills}")
    print(f"Overall agreement: {agreement_rate*100:.0f}% ({agreements}/{total_skills})")
    print()

    # Target check
    if agreement_rate >= 0.90:
        print("✅ Target achieved (≥90%)")
    else:
        print(f"⚠️  Below target (90%)")
        print(f"   Gap: {(0.90 - agreement_rate)*100:.0f} percentage points")
    print()

    # Agreement by category
    print("Agreement by category:")
    print()

    for category in CATEGORIES:
        category_agreements = 0
        category_total = 0

        for skill_slug in human_all:
            if skill_slug not in llm_all:
                continue

            human_score = human_all[skill_slug].get(category, {}).get("score", 0)
            llm_score = llm_all[skill_slug].get(category, {}).get("score", 0)

            if calculate_category_agreement(human_score, llm_score):
                category_agreements += 1
            category_total += 1

        cat_rate = category_agreements / category_total if category_total > 0 else 0
        status = "✓" if cat_rate >= 0.85 else "⚠️"

        print(f"  {status} {category}: {cat_rate*100:.0f}% ({category_agreements}/{category_total})")

    print()

    # Systematic biases
    biases = identify_systematic_biases(human_all, llm_all)

    if biases:
        print("Systematic biases detected:")
        print()

        for bias in biases:
            print(f"  • {bias['category']}")
            print(f"    Bias: {bias['bias']}")
            print(f"    Average diff: {bias['avg_diff']}")
            print(f"    Frequency: {bias['frequency']}")
        print()

        print("Recommendations:")
        print("1. Update rubrics for biased categories")
        print("2. Add examples addressing systematic errors")
        print("3. Re-run calibration on 10-skill subset")
        print()
    else:
        print("✅ No systematic biases detected")
        print()

    # Disagreements
    print("Skills with disagreements:")
    print()

    for skill_slug in human_all:
        if skill_slug not in llm_all:
            continue

        if not calculate_skill_agreement(human_all[skill_slug], llm_all[skill_slug]):
            print(f"  • {skill_slug}")

            for category in CATEGORIES:
                human_score = human_all[skill_slug].get(category, {}).get("score", 0)
                llm_score = llm_all[skill_slug].get(category, {}).get("score", 0)

                if not calculate_category_agreement(human_score, llm_score):
                    diff = llm_score - human_score
                    print(f"    - {category}: Human={human_score}, LLM={llm_score} (diff: {diff:+.1f})")

            print()

    # Final recommendation
    print("=" * 60)
    if agreement_rate >= 0.90 and not biases:
        print("Status: ✅ CALIBRATED - LLM-judge ready for production")
    elif agreement_rate >= 0.85:
        print("Status: ⚠️  MARGINAL - Consider rubric adjustments")
    else:
        print("Status: ❌ NEEDS_RECALIBRATION - Rubrics require updates")
    print("=" * 60)

def main():
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)

    human_dir = Path(sys.argv[1])
    llm_dir = Path(sys.argv[2])

    if not human_dir.exists():
        print(f"Error: Human grades directory not found: {human_dir}")
        sys.exit(1)

    if not llm_dir.exists():
        print(f"Error: LLM results directory not found: {llm_dir}")
        sys.exit(1)

    # Load grades
    human_grades = load_human_grades(human_dir)
    llm_grades = load_llm_grades(llm_dir)

    if not human_grades:
        print(f"Error: No human grades found in {human_dir}")
        sys.exit(1)

    if not llm_grades:
        print(f"Error: No LLM results found in {llm_dir}")
        sys.exit(1)

    # Generate report
    generate_report(human_grades, llm_grades)

if __name__ == "__main__":
    main()
