from flask import Flask, render_template, jsonify
from datetime import datetime
import os

app = Flask(__name__)

# Personal information from CV
PERSONAL_INFO = {
    'name': 'Umeokoli Vincent Tochukwu',
    'title': 'DevOps Cloud Engineer',
    'email': 'umeokolivincent@gmail.com',
    'phone': ['08137425765', '09070782052'],
    'linkedin': 'linkedin.com/in/umeokoli-vincent-493885172',
    'summary': '''Cloud Engineer with hands-on experience in cloud infrastructure, CI/CD pipelines,
                 and container orchestration. Currently interning at Hagital Consulting, contributing
                 to real-world cloud projects using AWS, Azure, Terraform, Docker, and Jenkins.
                 Proven background in technical support, systems administration, and cloud migrations.
                 Passionate about scalable cloud solutions and continuous integration for
                 high-availability systems.'''
}

EXPERIENCE = [
    {
        'title': 'Cloud & DevOps Engineer Intern',
        'company': 'Hagital Consulting',
        'location': 'Remote / Lagos, Nigeria',
        'period': '03/2024 - Present',
        'achievements': [
            'Collaborated on cloud infrastructure provisioning using Terraform on AWS and Azure.',
            'Deployed containerized applications using Docker and Kubernetes in test environments.',
            'Contributed to the setup of CI/CD pipelines using Jenkins and GitHub Actions.',
            'Supported monitoring and alerting systems for cloud environments.',
            'Participated in sprint planning and Agile DevOps culture.'
        ]
    },
    {
        'title': 'Microsoft 365 Technical Support Engineer',
        'company': 'TEK Experts Nigeria',
        'location': 'Hybrid / Lagos, Nigeria',
        'period': '11/2022 – 06/2023',
        'achievements': [
            'Successfully resolved technical issues for customers using Microsoft products across 5 continents.',
            'Maintained a high level of customer satisfaction through empathy, patience, and technical expertise.',
            'Collaborated with cross-functional teams including engineers, developers, and product managers.',
            'Created and maintained detailed documentation ensuring compliance with privacy and security policies.',
            'Received positive feedback and recognition for outstanding performance and customer advocacy.'
        ]
    },
    {
        'title': 'Technical Support Engineer',
        'company': 'Mobile Screens & Sound Ltd.',
        'location': 'Lagos',
        'period': '04/2021 – 10/2022',
        'achievements': [
            'Managed LED screen setup, troubleshooting, and synchronization using Nova LCT.',
            'Provided system maintenance, networking support, and technical direction for events.',
            'Supported live streaming operations using Vmix and Zoom with cloud integrations.'
        ]
    },
    {
        'title': 'Technical Support Officer',
        'company': 'Jigawa State Ministry of Finance and Economic Planning',
        'location': 'Jigawa State',
        'period': '06/2019 – 05/2020',
        'achievements': [
            'Provided Tier-1 support for system and network issues.',
            'Conducted system setups, user account configuration, and software rollouts.',
            'Maintained uptime of office IT infrastructure and documented support procedures.'
        ]
    }
]

EDUCATION = [
    {
        'institution': 'Federal Polytechnic Oko, Anambra State',
        'degree': 'Higher National Diploma (HND), Computer Engineering',
        'grade': 'Distinction',
        'year': '2018'
    },
    {
        'institution': 'Federal Polytechnic Oko, Anambra State',
        'degree': 'Ordinary National Diploma (OND), Computer Engineering',
        'grade': 'Upper Credit',
        'year': '2015'
    }
]

TECHNICAL_SKILLS = {
    'Cloud Platforms': ['AWS', 'Azure'],
    'DevOps Tools': ['Docker', 'Kubernetes', 'Jenkins', 'Terraform', 'Git', 'GitHub Actions'],
    'Operating Systems': ['Linux (Ubuntu)', 'Windows Server'],
    'CI/CD Pipelines': ['Jenkins', 'GitHub Actions'],
    'Infrastructure as Code': ['Terraform', 'ARM templates'],
    'Monitoring & Logging': ['Azure Monitor', 'CloudWatch'],
    'Networking & Security': ['VPC', 'IAM', 'Load Balancers', 'Firewall Rules'],
    'Version Control': ['Git', 'GitHub'],
    'Other Tools': ['M365 Office Suite', 'Vmix', 'Nova LCT']
}

CERTIFICATIONS = [
    {
        'name': 'Cloud & DevOps Engineering (AWS, Azure, Git, Docker, Kubernetes, Terraform, Jenkins)',
        'issuer': 'Hagital Consulting',
        'year': '2024'
    },
    {
        'name': 'Oracle Cloud & Google Cloud Platform',
        'issuer': 'In Progress',
        'year': 'Expected 2025'
    },
    {
        'name': 'Udemy Certifications in DevOps Tools',
        'issuer': 'In Progress',
        'year': 'Expected 2024'
    },
    {
        'name': 'Electrical Safety Training',
        'issuer': 'ETL Engineering Services',
        'year': '2021'
    },
    {
        'name': 'Health, Safety & Environment (HSE)',
        'issuer': 'Global Institute of Project Management',
        'year': '2019'
    },
    {
        'name': 'IT Essentials & Assembly Language',
        'issuer': 'Cisco Networking Academy',
        'year': '2018'
    },
    {
        'name': 'American Project Management Certification',
        'issuer': 'PMI',
        'year': '2013'
    }
]

@app.route('/')
def home():
    """Home page with complete portfolio"""
    return render_template('index.html',
                         personal_info=PERSONAL_INFO,
                         experience=EXPERIENCE,
                         education=EDUCATION,
                         skills=TECHNICAL_SKILLS,
                         certifications=CERTIFICATIONS)

@app.route('/api/profile')
def api_profile():
    """API endpoint for profile data"""
    return jsonify({
        'personal_info': PERSONAL_INFO,
        'experience': EXPERIENCE,
        'education': EDUCATION,
        'skills': TECHNICAL_SKILLS,
        'certifications': CERTIFICATIONS
    })

@app.route('/health')
def health_check():
    """Health check endpoint for Kubernetes"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.utcnow().isoformat(),
        'version': '1.0.0'
    })

@app.route('/api/contact')
def contact_info():
    """Contact information API endpoint"""
    return jsonify({
        'name': PERSONAL_INFO['name'],
        'email': PERSONAL_INFO['email'],
        'phone': PERSONAL_INFO['phone'],
        'linkedin': PERSONAL_INFO['linkedin']
    })

@app.route('/api/skills')
def skills_api():
    """Skills API endpoint"""
    return jsonify(TECHNICAL_SKILLS)

@app.route('/experience')
def experience_page():
    """Dedicated experience page"""
    return render_template('experience.html', experience=EXPERIENCE)

@app.route('/skills')
def skills_page():
    """Dedicated skills page"""
    return render_template('skills.html', skills=TECHNICAL_SKILLS)

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)