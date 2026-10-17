"""
Rule-Based Career Recommendation Engine (v2)
Covers all 44 departments across 6 faculties at ADUSTECH
"""

SKILL_LEVEL = {'Beginner': 1, 'Intermediate': 2, 'Advanced': 3}


def evaluate_rule(rule, profile):
    field    = rule['condition_field']
    operator = rule['condition_operator']
    value    = rule['condition_value']

    if field == 'cgpa':
        student_val = float(profile.get('cgpa', 0))
        rule_val    = float(value)
        if operator == '>=':  return student_val >= rule_val
        if operator == '>':   return student_val > rule_val
        if operator == '<=':  return student_val <= rule_val
        if operator == '<':   return student_val < rule_val

    elif field == 'skill_level':
        student_level = SKILL_LEVEL.get(profile.get('skill_level', 'Beginner'), 1)
        rule_level    = SKILL_LEVEL.get(value, 1)
        if operator == '>=':  return student_level >= rule_level
        if operator == '==':  return student_level == rule_level

    elif field == 'interests':
        student_interests = profile.get('interests', '')
        if operator == 'CONTAINS':
            return value.lower() in student_interests.lower()

    elif field == 'preferred_field':
        if operator == 'CONTAINS':
            return value.lower() in profile.get('preferred_field', '').lower()

    elif field == 'faculty':
        if operator == '==':
            return profile.get('faculty', '') == value

    elif field == 'department':
        if operator == '==':
            return profile.get('department', '') == value
        if operator == 'CONTAINS':
            return value.lower() in profile.get('department', '').lower()

    return False


def get_recommendations(profile, rules):
    career_scores = {}

    for rule in rules:
        if evaluate_rule(rule, profile):
            cid = rule['career_id']
            if cid not in career_scores:
                career_scores[cid] = {
                    'career_id':   cid,
                    'career_name': rule['career_name'],
                    'description': rule.get('description', ''),
                    'score':       0,
                    'reasons':     []
                }
            career_scores[cid]['score'] += 1
            career_scores[cid]['reasons'].append(rule['reason_text'])

    sorted_careers = sorted(career_scores.values(), key=lambda x: x['score'], reverse=True)

    results = []
    for career in sorted_careers[:6]:
        results.append({
            'career_id':   career['career_id'],
            'career_name': career['career_name'],
            'description': career['description'],
            'score':       career['score'],
            'reason_text': career['reasons'][0],
            'all_reasons': career['reasons'],
        })

    if not results:
        results = [{
            'career_id': None,
            'career_name': 'General Career Exploration Recommended',
            'description': 'Your profile did not strongly match a specific career path. Consider exploring careers related to your department with a career counsellor.',
            'score': 0,
            'reason_text': 'Update your interests and preferred career field for more precise recommendations.',
            'all_reasons': [],
        }]

    return results
