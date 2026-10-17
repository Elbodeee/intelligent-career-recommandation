-- ══════════════════════════════════════════════════════
--  ADUSTECH Career Path Recommendation System (v2)
--  Covers all 6 Faculties / 44 Departments
-- ══════════════════════════════════════════════════════

CREATE DATABASE IF NOT EXISTS career_system_v2;
USE career_system_v2;

CREATE TABLE IF NOT EXISTS users (
    user_id       INT AUTO_INCREMENT PRIMARY KEY,
    full_name     VARCHAR(150) NOT NULL,
    reg_number    VARCHAR(50)  DEFAULT '',
    email         VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role          ENUM('student','admin') DEFAULT 'student',
    created_at    DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS student_profiles (
    profile_id        INT AUTO_INCREMENT PRIMARY KEY,
    user_id           INT NOT NULL,
    reg_number        VARCHAR(50),
    faculty           VARCHAR(150),
    department        VARCHAR(150),
    level             VARCHAR(20),
    cgpa              DECIMAL(3,2),
    skill_level       VARCHAR(20),
    interests         TEXT,
    preferred_field   VARCHAR(150),
    updated_at        DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS careers (
    career_id          INT AUTO_INCREMENT PRIMARY KEY,
    career_name        VARCHAR(150) NOT NULL,
    description        TEXT,
    relevant_faculties TEXT,
    required_skills    TEXT
);

CREATE TABLE IF NOT EXISTS recommendation_rules (
    rule_id            INT AUTO_INCREMENT PRIMARY KEY,
    condition_field    VARCHAR(100) NOT NULL,
    condition_operator VARCHAR(20)  NOT NULL,
    condition_value    VARCHAR(200) NOT NULL,
    career_id          INT NOT NULL,
    reason_text        TEXT,
    FOREIGN KEY (career_id) REFERENCES careers(career_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS recommendation_history (
    history_id     INT AUTO_INCREMENT PRIMARY KEY,
    user_id        INT NOT NULL,
    career_id      INT NOT NULL,
    reason_text    TEXT,
    recommended_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id)   REFERENCES users(user_id)    ON DELETE CASCADE,
    FOREIGN KEY (career_id) REFERENCES careers(career_id) ON DELETE CASCADE
);

-- Admin account (password: admin123)
INSERT IGNORE INTO users (full_name, reg_number, email, password_hash, role) VALUES
('System Administrator','ADMIN001','admin@adustech.edu.ng',
'scrypt:32768:8:1$lC1jWokaaH0TnEno$d7c58891747aa0f01909831f1f294022fbe0c03f6805542a05bf97481370775d2a25fd29382165fbc93a36a2e5a81f789665e7a53a747ba56bf2b58b0543a008',
'admin');

-- Careers
INSERT INTO careers (career_name, description, relevant_faculties, required_skills) VALUES
('Software Engineer','Designs, develops, and maintains software systems and applications.','Faculty of Computing and Mathematical Sciences','Programming, Problem Solving, System Design'),
('Data Scientist','Analyses large datasets using statistics and machine learning to extract insights.','Faculty of Computing and Mathematical Sciences','Python, Statistics, Machine Learning, SQL'),
('Cybersecurity Analyst','Protects systems and networks from digital attacks and unauthorised access.','Faculty of Computing and Mathematical Sciences','Network Security, Ethical Hacking, Risk Assessment'),
('Machine Learning Engineer','Builds and deploys AI and machine learning models for real-world applications.','Faculty of Computing and Mathematical Sciences','Python, TensorFlow, Deep Learning'),
('Web Developer','Builds and maintains websites and web applications.','Faculty of Computing and Mathematical Sciences','HTML, CSS, JavaScript, Backend Frameworks'),
('Network Engineer','Designs and manages computer networks within organisations.','Faculty of Computing and Mathematical Sciences','Cisco Networking, TCP/IP, Routing'),
('Database Administrator','Manages and maintains databases for secure, efficient data storage.','Faculty of Computing and Mathematical Sciences','SQL, MySQL, Database Design'),
('Actuarial Analyst / Statistician','Applies statistical models to assess risk in insurance, finance, and research.','Faculty of Computing and Mathematical Sciences','Statistics, Data Modelling, Mathematics'),

('Civil / Structural Engineer','Designs and supervises construction of infrastructure such as roads, bridges, and buildings.','Faculty of Engineering','AutoCAD, Structural Analysis, Project Management'),
('Electrical / Power Systems Engineer','Designs and maintains electrical systems, power grids, and installations.','Faculty of Engineering','Circuit Design, Power Systems, Electronics'),
('Mechanical Engineer','Designs, analyses, and maintains mechanical systems and machinery.','Faculty of Engineering','CAD, Thermodynamics, Manufacturing Processes'),
('Automotive Engineer','Designs, develops, and tests vehicles and automotive systems.','Faculty of Engineering','Vehicle Systems, CAD, Mechanical Design'),
('Mechatronics / Robotics Engineer','Combines mechanical, electronic, and software engineering to design automated systems.','Faculty of Engineering','Robotics, Control Systems, Embedded Programming'),
('Water Resources Engineer','Plans and manages water supply, irrigation, and environmental water systems.','Faculty of Engineering','Hydrology, Environmental Modelling, Design'),
('Agricultural Engineer','Applies engineering principles to agricultural production and processing systems.','Faculty of Engineering, Faculty of Agriculture and Agricultural Technology','Farm Machinery, Irrigation Design, CAD'),

('Architect','Designs buildings and oversees construction to ensure functional and aesthetic standards.','Faculty of Earth and Environmental Sciences','AutoCAD, Design Principles, Building Codes'),
('Estate Surveyor / Valuer','Manages, values, and advises on property and real estate investments.','Faculty of Earth and Environmental Sciences','Property Valuation, Negotiation, Market Analysis'),
('Urban and Regional Planner','Plans land use and development of cities, towns, and regions.','Faculty of Earth and Environmental Sciences','GIS, Urban Design, Policy Analysis'),
('Quantity Surveyor','Manages construction costs and contracts from planning through to completion.','Faculty of Earth and Environmental Sciences','Cost Estimation, Contract Management'),
('Geologist / Mining Analyst','Studies earth materials and processes to support mining and resource exploration.','Faculty of Earth and Environmental Sciences','Geological Mapping, Field Research'),
('Meteorologist / Climate Analyst','Studies weather patterns and climate data for forecasting and research.','Faculty of Earth and Environmental Sciences','Data Analysis, Climate Modelling'),
('Building Technologist / Construction Manager','Supervises construction projects and building technology processes.','Faculty of Earth and Environmental Sciences','Construction Management, Site Supervision'),
('GIS Analyst','Uses mapping software to analyse spatial and geographic data.','Faculty of Earth and Environmental Sciences','GIS Software, Cartography, Data Analysis'),

('Agricultural Economist / Extension Officer','Advises farmers and organisations on agricultural economics and productivity.','Faculty of Agriculture and Agricultural Technology','Economic Analysis, Extension Services'),
('Animal Scientist / Livestock Manager','Manages livestock production, breeding, and animal health programmes.','Faculty of Agriculture and Agricultural Technology','Animal Husbandry, Nutrition, Breeding'),
('Crop Scientist / Agronomist','Researches and advises on crop production, breeding, and soil management.','Faculty of Agriculture and Agricultural Technology','Crop Management, Field Research'),
('Fisheries and Aquaculture Specialist','Manages fish farming operations and aquatic resource conservation.','Faculty of Agriculture and Agricultural Technology','Aquaculture Management, Water Quality Analysis'),
('Food Technologist / Quality Analyst','Develops and ensures the quality and safety of food products.','Faculty of Agriculture and Agricultural Technology','Food Processing, Quality Control, Lab Analysis'),
('Forestry / Wildlife Conservation Officer','Manages forest resources and wildlife conservation programmes.','Faculty of Agriculture and Agricultural Technology','Conservation Planning, Field Surveys'),
('Soil Scientist','Studies soil properties to support agricultural and environmental management.','Faculty of Agriculture and Agricultural Technology','Soil Analysis, Lab Techniques'),

('Biomedical Scientist / Medical Laboratory Scientist','Conducts laboratory tests to support medical diagnosis and research.','Faculty of Science','Lab Techniques, Microscopy, Data Recording'),
('Biochemist / Research Scientist','Studies chemical processes within living organisms for research and industry.','Faculty of Science','Lab Research, Analytical Chemistry'),
('Microbiologist','Studies microorganisms for healthcare, food safety, and environmental applications.','Faculty of Science','Microscopy, Culturing Techniques, Lab Safety'),
('Industrial Chemist','Applies chemistry principles to develop and improve industrial products and processes.','Faculty of Science','Chemical Analysis, Lab Techniques'),
('Physicist / Research Analyst','Conducts research and analysis in physical sciences and applied physics.','Faculty of Science','Data Analysis, Research Methods, Instrumentation'),
('Science Laboratory Technologist','Manages laboratory operations and supports scientific experiments.','Faculty of Science','Lab Equipment Handling, Safety Protocols'),

('Subject Teacher / Educator','Teaches specialised subjects at secondary or tertiary education levels.','Faculty of Science and Technical Education','Curriculum Design, Classroom Management, Communication'),
('Technical and Vocational Education Instructor','Trains students in technical and vocational skills for industry readiness.','Faculty of Science and Technical Education','Technical Training, Hands-on Instruction'),
('Educational Administrator / Curriculum Developer','Plans and manages educational programmes and curricula.','Faculty of Science and Technical Education','Curriculum Planning, Administration'),
('Librarian / Information Scientist','Manages information resources and library systems for research and public use.','Faculty of Science and Technical Education','Information Management, Cataloguing, Research Support'),
('Sports Scientist / Physical Education Instructor','Trains and advises on physical fitness, sports science, and health.','Faculty of Science and Technical Education','Physical Training, Sports Science'),
('Health Educator','Promotes public health awareness and education programmes.','Faculty of Science and Technical Education','Health Communication, Community Outreach');

-- Rules: link department -> career, plus CGPA/skill/interest boosters
INSERT INTO recommendation_rules (condition_field, condition_operator, condition_value, career_id, reason_text) VALUES
-- Computing faculty
('department','==','Computer Science',1,'Your Computer Science background is directly relevant to Software Engineering.'),
('department','==','Computer Science',2,'Your Computer Science background supports a career in Data Science.'),
('department','==','Computer Science',4,'Your Computer Science background suits Machine Learning Engineering.'),
('department','==','Information and Communication Technology (ICT)',3,'Your ICT background matches Cybersecurity Analysis well.'),
('department','==','Information and Communication Technology (ICT)',6,'Your ICT background is a strong match for Network Engineering.'),
('department','==','Mathematics',8,'Your Mathematics background suits a career as an Actuarial Analyst or Statistician.'),
('department','==','Statistics',8,'Your Statistics background is directly relevant to actuarial and data analysis roles.'),
('interests','CONTAINS','Software Development',1,'Your interest in software development matches Software Engineering.'),
('interests','CONTAINS','Data Analysis',2,'Your interest in data analysis matches Data Science.'),
('interests','CONTAINS','Cybersecurity',3,'Your interest in cybersecurity matches this career directly.'),
('interests','CONTAINS','Artificial Intelligence',4,'Your interest in AI matches Machine Learning Engineering.'),
('interests','CONTAINS','Web Development',5,'Your interest in web development matches this career directly.'),
('interests','CONTAINS','Network Engineering',6,'Your interest in networking matches Network Engineering.'),
('interests','CONTAINS','Database Administration',7,'Your interest in databases matches Database Administration.'),
('cgpa','>=','3.50',1,'Your strong CGPA supports a competitive career in Software Engineering.'),

-- Engineering faculty
('department','==','Civil Engineering',9,'Your Civil Engineering background matches this career directly.'),
('department','==','Electrical Engineering',10,'Your Electrical Engineering background matches this career directly.'),
('department','==','Mechanical Engineering',11,'Your Mechanical Engineering background matches this career directly.'),
('department','==','Automotive Engineering',12,'Your Automotive Engineering background matches this career directly.'),
('department','==','Mechatronics Engineering',13,'Your Mechatronics Engineering background matches this career directly.'),
('department','==','Water Resources and Environmental Engineering',14,'Your background matches Water Resources Engineering directly.'),
('department','==','Agricultural Engineering',15,'Your Agricultural Engineering background matches this career directly.'),

-- Earth and Environmental Sciences
('department','==','Architecture',16,'Your Architecture background matches this career directly.'),
('department','==','Estate Management',17,'Your Estate Management background matches this career directly.'),
('department','==','Urban and Regional Planning',18,'Your background matches Urban and Regional Planning directly.'),
('department','==','Quantity Surveying',19,'Your Quantity Surveying background matches this career directly.'),
('department','==','Geology',20,'Your Geology background matches this career directly.'),
('department','==','Meteorology',21,'Your Meteorology background matches this career directly.'),
('department','==','Building Technology',22,'Your Building Technology background matches this career directly.'),
('department','==','Geography',23,'Your Geography background suits a career in GIS Analysis.'),

-- Agriculture faculty
('department','==','Agricultural Economics and Extension',24,'Your background matches Agricultural Economics directly.'),
('department','==','Animal Science',25,'Your Animal Science background matches this career directly.'),
('department','==','Crop Science',26,'Your Crop Science background matches this career directly.'),
('department','==','Fisheries and Aquaculture',27,'Your background matches Fisheries and Aquaculture directly.'),
('department','==','Food Science and Technology',28,'Your Food Science background matches this career directly.'),
('department','==','Forestry and Wildlife Management',29,'Your background matches Forestry and Wildlife Conservation directly.'),
('department','==','Soil Science',30,'Your Soil Science background matches this career directly.'),

-- Science faculty
('department','==','Biochemistry',32,'Your Biochemistry background matches this career directly.'),
('department','==','Biology',31,'Your Biology background matches Biomedical Science directly.'),
('department','==','Microbiology',33,'Your Microbiology background matches this career directly.'),
('department','==','Chemistry',34,'Your Chemistry background matches Industrial Chemistry directly.'),
('department','==','Physics',35,'Your Physics background matches this career directly.'),
('department','==','Science Laboratory Technology (SLT)',36,'Your SLT background matches this career directly.'),
('interests','CONTAINS','Healthcare / Medical Sciences',31,'Your interest in healthcare matches Biomedical Science.'),

-- Science and Technical Education faculty
('department','CONTAINS','Education',37,'Your education-focused background matches Teaching directly.'),
('department','CONTAINS','Technology Education',38,'Your background matches Technical and Vocational Education.'),
('department','==','Library and Information Science',40,'Your background matches Library and Information Science directly.'),
('department','==','Human Kinetics',41,'Your background matches Sports Science directly.'),
('department','==','Health Education',42,'Your background matches Health Education directly.'),
('interests','CONTAINS','Teaching / Education',37,'Your interest in teaching matches an education career directly.');
