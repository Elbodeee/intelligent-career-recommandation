from flask import Flask, render_template, request, redirect, url_for, session, flash
from flask_mysqldb import MySQL
from werkzeug.security import generate_password_hash, check_password_hash
from recommendation_engine import get_recommendations
from data import FACULTIES, DEPARTMENT_TO_FACULTY, INTEREST_OPTIONS, CAREER_FIELDS

app = Flask(__name__)
app.secret_key = 'adustech_career_v2_secret'

app.config['MYSQL_HOST'] = 'localhost'
app.config['MYSQL_USER'] = 'root'
app.config['MYSQL_PASSWORD'] = ''
app.config['MYSQL_DB'] = 'career_system_v2'
app.config['MYSQL_CURSORCLASS'] = 'DictCursor'

mysql = MySQL(app)


@app.route('/')
def index():
    return render_template('index.html', faculty_count=len(FACULTIES),
                           dept_count=len(DEPARTMENT_TO_FACULTY))


# ── STUDENT REGISTER ──
@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        full_name  = request.form['full_name'].strip()
        reg_number = request.form['reg_number'].strip()
        email      = request.form['email'].strip()
        password   = request.form['password']

        cursor = mysql.connection.cursor()
        cursor.execute("SELECT * FROM users WHERE email = %s", (email,))
        if cursor.fetchone():
            flash('An account with this email already exists.', 'danger')
        else:
            hashed = generate_password_hash(password)
            cursor.execute(
                "INSERT INTO users (full_name, reg_number, email, password_hash, role) VALUES (%s,%s,%s,%s,'student')",
                (full_name, reg_number, email, hashed)
            )
            mysql.connection.commit()
            flash('Registration successful! Please log in.', 'success')
            return redirect(url_for('login'))

    return render_template('register.html')


@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email    = request.form['email'].strip()
        password = request.form['password']

        cursor = mysql.connection.cursor()
        cursor.execute("SELECT * FROM users WHERE email = %s", (email,))
        user = cursor.fetchone()

        if user and check_password_hash(user['password_hash'], password):
            session['user_id']   = user['user_id']
            session['full_name'] = user['full_name']
            session['role']      = user['role']
            return redirect(url_for('admin_dashboard') if user['role'] == 'admin' else url_for('student_dashboard'))
        else:
            flash('Invalid email or password.', 'danger')

    return render_template('login.html')


@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('index'))


@app.route('/dashboard')
def student_dashboard():
    if 'user_id' not in session or session['role'] != 'student':
        return redirect(url_for('login'))

    cursor = mysql.connection.cursor()
    cursor.execute("SELECT * FROM student_profiles WHERE user_id = %s", (session['user_id'],))
    profile = cursor.fetchone()

    cursor.execute(
        """SELECT rh.*, c.career_name, c.description
           FROM recommendation_history rh
           JOIN careers c ON rh.career_id = c.career_id
           WHERE rh.user_id = %s ORDER BY rh.recommended_at DESC LIMIT 10""",
        (session['user_id'],)
    )
    history = cursor.fetchall()

    return render_template('student_dashboard.html', profile=profile, history=history)


@app.route('/profile', methods=['GET', 'POST'])
def student_profile():
    if 'user_id' not in session or session['role'] != 'student':
        return redirect(url_for('login'))

    cursor = mysql.connection.cursor()

    if request.method == 'POST':
        department  = request.form['department']
        faculty     = DEPARTMENT_TO_FACULTY.get(department, '')
        level       = request.form['level']
        cgpa        = float(request.form['cgpa'])
        skill_level = request.form['skill_level']
        interests   = ', '.join(request.form.getlist('interests'))
        preferred_field = request.form['preferred_field']

        cursor.execute("SELECT * FROM student_profiles WHERE user_id = %s", (session['user_id'],))
        existing = cursor.fetchone()

        if existing:
            cursor.execute(
                """UPDATE student_profiles SET faculty=%s, department=%s, level=%s, cgpa=%s,
                   skill_level=%s, interests=%s, preferred_field=%s WHERE user_id=%s""",
                (faculty, department, level, cgpa, skill_level, interests, preferred_field, session['user_id'])
            )
        else:
            cursor.execute("SELECT reg_number FROM users WHERE user_id=%s", (session['user_id'],))
            reg = cursor.fetchone()['reg_number']
            cursor.execute(
                """INSERT INTO student_profiles
                   (user_id, reg_number, faculty, department, level, cgpa, skill_level, interests, preferred_field)
                   VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s)""",
                (session['user_id'], reg, faculty, department, level, cgpa, skill_level, interests, preferred_field)
            )
        mysql.connection.commit()

        profile_data = {
            'faculty': faculty, 'department': department, 'cgpa': cgpa,
            'skill_level': skill_level, 'interests': interests, 'preferred_field': preferred_field,
        }
        cursor.execute("SELECT * FROM recommendation_rules JOIN careers USING(career_id)")
        rules = cursor.fetchall()
        recommendations = get_recommendations(profile_data, rules)

        cursor.execute("DELETE FROM recommendation_history WHERE user_id=%s", (session['user_id'],))
        for rec in recommendations:
            if rec['career_id']:
                cursor.execute(
                    "INSERT INTO recommendation_history (user_id, career_id, reason_text) VALUES (%s,%s,%s)",
                    (session['user_id'], rec['career_id'], rec['reason_text'])
                )
        mysql.connection.commit()

        return render_template('recommendations.html', recommendations=recommendations)

    cursor.execute("SELECT * FROM student_profiles WHERE user_id = %s", (session['user_id'],))
    profile = cursor.fetchone()

    return render_template('student_profile.html', profile=profile, faculties=FACULTIES,
                           interests=INTEREST_OPTIONS, career_fields=CAREER_FIELDS)


@app.route('/admin')
def admin_dashboard():
    if 'user_id' not in session or session['role'] != 'admin':
        return redirect(url_for('login'))

    cursor = mysql.connection.cursor()
    cursor.execute("SELECT COUNT(*) as cnt FROM users WHERE role='student'")
    student_count = cursor.fetchone()['cnt']
    cursor.execute("SELECT COUNT(*) as cnt FROM careers")
    career_count = cursor.fetchone()['cnt']
    cursor.execute("SELECT COUNT(*) as cnt FROM recommendation_history")
    rec_count = cursor.fetchone()['cnt']
    cursor.execute("SELECT COUNT(*) as cnt FROM recommendation_rules")
    rules_count = cursor.fetchone()['cnt']

    cursor.execute(
        """SELECT u.full_name, u.email, u.reg_number, sp.faculty, sp.department, sp.cgpa
           FROM users u LEFT JOIN student_profiles sp ON u.user_id = sp.user_id
           WHERE u.role='student' ORDER BY u.created_at DESC LIMIT 10"""
    )
    recent_students = cursor.fetchall()

    cursor.execute(
        """SELECT c.career_name, COUNT(rh.career_id) as total
           FROM recommendation_history rh JOIN careers c ON rh.career_id = c.career_id
           GROUP BY rh.career_id ORDER BY total DESC LIMIT 5"""
    )
    top_careers = cursor.fetchall()

    cursor.execute(
        """SELECT sp.faculty, COUNT(*) as total FROM student_profiles sp
           GROUP BY sp.faculty ORDER BY total DESC"""
    )
    faculty_breakdown = cursor.fetchall()

    return render_template('admin_dashboard.html', student_count=student_count,
                           career_count=career_count, rec_count=rec_count, rules_count=rules_count,
                           recent_students=recent_students, top_careers=top_careers,
                           faculty_breakdown=faculty_breakdown)


@app.route('/admin/careers', methods=['GET', 'POST'])
def admin_careers():
    if 'user_id' not in session or session['role'] != 'admin':
        return redirect(url_for('login'))

    cursor = mysql.connection.cursor()
    if request.method == 'POST':
        action = request.form.get('action')
        if action == 'add':
            cursor.execute(
                "INSERT INTO careers (career_name, description, relevant_faculties, required_skills) VALUES (%s,%s,%s,%s)",
                (request.form['career_name'], request.form['description'],
                 request.form['relevant_faculties'], request.form['required_skills'])
            )
            mysql.connection.commit()
            flash('Career added successfully.', 'success')
        elif action == 'delete':
            cursor.execute("DELETE FROM careers WHERE career_id=%s", (request.form['career_id'],))
            mysql.connection.commit()
            flash('Career deleted.', 'warning')

    cursor.execute("SELECT * FROM careers ORDER BY career_name")
    careers = cursor.fetchall()
    return render_template('admin_careers.html', careers=careers)


@app.route('/admin/rules', methods=['GET', 'POST'])
def admin_rules():
    if 'user_id' not in session or session['role'] != 'admin':
        return redirect(url_for('login'))

    cursor = mysql.connection.cursor()
    if request.method == 'POST':
        action = request.form.get('action')
        if action == 'add':
            cursor.execute(
                """INSERT INTO recommendation_rules
                   (condition_field, condition_operator, condition_value, career_id, reason_text)
                   VALUES (%s,%s,%s,%s,%s)""",
                (request.form['condition_field'], request.form['condition_operator'],
                 request.form['condition_value'], request.form['career_id'], request.form['reason_text'])
            )
            mysql.connection.commit()
            flash('Rule added successfully.', 'success')
        elif action == 'delete':
            cursor.execute("DELETE FROM recommendation_rules WHERE rule_id=%s", (request.form['rule_id'],))
            mysql.connection.commit()
            flash('Rule deleted.', 'warning')

    cursor.execute(
        """SELECT r.*, c.career_name FROM recommendation_rules r
           JOIN careers c ON r.career_id = c.career_id ORDER BY r.rule_id"""
    )
    rules = cursor.fetchall()
    cursor.execute("SELECT career_id, career_name FROM careers ORDER BY career_name")
    careers = cursor.fetchall()
    return render_template('admin_rules.html', rules=rules, careers=careers)


@app.route('/admin/students')
def admin_students():
    if 'user_id' not in session or session['role'] != 'admin':
        return redirect(url_for('login'))

    cursor = mysql.connection.cursor()
    cursor.execute(
        """SELECT u.user_id, u.full_name, u.email, u.reg_number, u.created_at,
                  sp.faculty, sp.department, sp.level, sp.cgpa, sp.skill_level
           FROM users u LEFT JOIN student_profiles sp ON u.user_id = sp.user_id
           WHERE u.role='student' ORDER BY u.full_name"""
    )
    students = cursor.fetchall()
    return render_template('admin_students.html', students=students)


@app.route('/admin/history')
def admin_history():
    if 'user_id' not in session or session['role'] != 'admin':
        return redirect(url_for('login'))

    cursor = mysql.connection.cursor()
    cursor.execute(
        """SELECT u.full_name, u.reg_number, sp.department, c.career_name,
                  rh.reason_text, rh.recommended_at
           FROM recommendation_history rh
           JOIN users u ON rh.user_id = u.user_id
           LEFT JOIN student_profiles sp ON sp.user_id = u.user_id
           JOIN careers c ON rh.career_id = c.career_id
           ORDER BY rh.recommended_at DESC"""
    )
    history = cursor.fetchall()
    return render_template('admin_history.html', history=history)


@app.route('/get_departments/<faculty>')
def get_departments(faculty):
    from flask import jsonify
    return jsonify(FACULTIES.get(faculty, []))


if __name__ == '__main__':
    app.run(debug=True)
