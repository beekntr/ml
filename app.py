"""
Student Type Prediction Web Application
Flask Backend - End-Semester ML Lab Project

This application predicts student type (Topper, Backbencher, Crammer, All-Rounder)
based on academic and lifestyle inputs using a trained Machine Learning model.
"""

from flask import Flask, render_template, request, jsonify
import pickle
import numpy as np
import os

# Initialize Flask application
app = Flask(__name__)

# Load the trained model and label encoder
MODEL_PATH = 'model/student_model.pkl'
ENCODER_PATH = 'model/label_encoder.pkl'

try:
    with open(MODEL_PATH, 'rb') as model_file:
        model = pickle.load(model_file)
    with open(ENCODER_PATH, 'rb') as encoder_file:
        label_encoder = pickle.load(encoder_file)
    print("✅ Model and encoder loaded successfully!")
except FileNotFoundError:
    print("⚠️ Model files not found. Please train the model first by running training_notebook.ipynb")
    model = None
    label_encoder = None

# Student type descriptions and characteristics
STUDENT_DESCRIPTIONS = {
    'Topper': {
        'emoji': '🏆',
        'description': 'You are a dedicated and consistent learner!',
        'characteristics': [
            'High study hours and excellent attendance',
            'Completes all assignments on time',
            'Balanced lifestyle with proper sleep',
            'Limited social media usage',
            'No backlogs'
        ],
        'advice': 'Keep up the excellent work! Your dedication is inspiring.',
        'color': '#2ecc71'
    },
    'Backbencher': {
        'emoji': '😎',
        'description': 'You prefer a more relaxed approach to academics.',
        'characteristics': [
            'Low study hours and poor attendance',
            'Often skips assignments',
            'High social media usage',
            'May have backlogs',
            'Needs to improve time management'
        ],
        'advice': 'Consider increasing study time and attending classes regularly. Small steps can make a big difference!',
        'color': '#e74c3c'
    },
    'Crammer': {
        'emoji': '📚',
        'description': 'You are the last-minute learning champion!',
        'characteristics': [
            'Studies intensively before exams',
            'Moderate attendance',
            'Limited daily study routine',
            'May skip regular assignments',
            'No backlogs due to exam cramming'
        ],
        'advice': 'Try to develop a consistent study routine. Regular practice is more effective than last-minute cramming!',
        'color': '#f39c12'
    },
    'All-Rounder': {
        'emoji': '⭐',
        'description': 'You maintain a great balance in all aspects!',
        'characteristics': [
            'Good study hours and attendance',
            'Completes assignments regularly',
            'Moderate social media usage',
            'Maintains healthy sleep schedule',
            'No backlogs'
        ],
        'advice': 'Excellent balance! You manage academics and personal life well.',
        'color': '#3498db'
    }
}


@app.route('/')
def index():
    """
    Home page route - displays the input form
    """
    return render_template('index.html')


@app.route('/predict', methods=['POST'])
def predict():
    """
    Prediction route - processes form data and returns prediction
    
    Expects POST request with form data:
    - study_hours: integer (0-10)
    - attendance: integer (0-100)
    - assignments: string ('yes' or 'no')
    - social_media: integer (0-10)
    - sleep_hours: integer (0-10)
    - backlogs: string ('yes' or 'no')
    
    Returns: Renders result.html with prediction and details
    """
    
    if model is None:
        return render_template('error.html', 
                             error_message="Model not loaded. Please train the model first.")
    
    try:
        # Extract form data
        study_hours = int(request.form.get('study_hours', 0))
        attendance = int(request.form.get('attendance', 0))
        assignments = 1 if request.form.get('assignments', 'no').lower() == 'yes' else 0
        social_media = int(request.form.get('social_media', 0))
        sleep_hours = int(request.form.get('sleep_hours', 0))
        backlogs = 1 if request.form.get('backlogs', 'no').lower() == 'yes' else 0
        
        # Validate input ranges
        if not (0 <= study_hours <= 24):
            raise ValueError("Study hours must be between 0 and 24")
        if not (0 <= attendance <= 100):
            raise ValueError("Attendance must be between 0 and 100")
        if not (0 <= social_media <= 24):
            raise ValueError("Social media hours must be between 0 and 24")
        if not (0 <= sleep_hours <= 24):
            raise ValueError("Sleep hours must be between 0 and 24")
        
        # Prepare input for prediction
        input_features = np.array([[study_hours, attendance, assignments, 
                                   social_media, sleep_hours, backlogs]])
        
        # Make prediction
        prediction_encoded = model.predict(input_features)[0]
        student_type = label_encoder.inverse_transform([prediction_encoded])[0]
        
        # Get prediction probability (if available)
        try:
            probabilities = model.predict_proba(input_features)[0]
            confidence = max(probabilities) * 100
        except AttributeError:
            # Some models don't have predict_proba
            confidence = 95.0
        
        # Get student description
        student_info = STUDENT_DESCRIPTIONS.get(student_type, {
            'emoji': '🎓',
            'description': 'Student type predicted successfully!',
            'characteristics': ['N/A'],
            'advice': 'Keep learning!',
            'color': '#34495e'
        })
        
        # Prepare input summary for display
        input_summary = {
            'study_hours': study_hours,
            'attendance': attendance,
            'assignments': 'Yes' if assignments else 'No',
            'social_media': social_media,
            'sleep_hours': sleep_hours,
            'backlogs': 'Yes' if backlogs else 'No'
        }
        
        # Render result page
        return render_template('result.html',
                             student_type=student_type,
                             emoji=student_info['emoji'],
                             description=student_info['description'],
                             characteristics=student_info['characteristics'],
                             advice=student_info['advice'],
                             color=student_info['color'],
                             confidence=round(confidence, 2),
                             input_summary=input_summary)
    
    except ValueError as ve:
        return render_template('error.html', 
                             error_message=f"Invalid input: {str(ve)}")
    except Exception as e:
        return render_template('error.html', 
                             error_message=f"An error occurred: {str(e)}")


@app.route('/api/predict', methods=['POST'])
def api_predict():
    """
    API endpoint for predictions (JSON response)
    
    Expects JSON data with same fields as form
    Returns: JSON with prediction and confidence
    """
    
    if model is None:
        return jsonify({'error': 'Model not loaded'}), 500
    
    try:
        data = request.get_json()
        
        # Extract and validate data
        study_hours = int(data.get('study_hours', 0))
        attendance = int(data.get('attendance', 0))
        assignments = 1 if str(data.get('assignments', 'no')).lower() == 'yes' else 0
        social_media = int(data.get('social_media', 0))
        sleep_hours = int(data.get('sleep_hours', 0))
        backlogs = 1 if str(data.get('backlogs', 'no')).lower() == 'yes' else 0
        
        # Prepare and predict
        input_features = np.array([[study_hours, attendance, assignments, 
                                   social_media, sleep_hours, backlogs]])
        
        prediction_encoded = model.predict(input_features)[0]
        student_type = label_encoder.inverse_transform([prediction_encoded])[0]
        
        # Get confidence
        try:
            probabilities = model.predict_proba(input_features)[0]
            confidence = max(probabilities) * 100
        except AttributeError:
            confidence = 95.0
        
        return jsonify({
            'success': True,
            'prediction': student_type,
            'confidence': round(confidence, 2),
            'description': STUDENT_DESCRIPTIONS[student_type]['description']
        })
    
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 400


@app.route('/about')
def about():
    """
    About page - project information
    """
    return render_template('about.html')


@app.errorhandler(404)
def page_not_found(e):
    """
    Handle 404 errors
    """
    return render_template('error.html', 
                         error_message="Page not found (404)"), 404


@app.errorhandler(500)
def internal_server_error(e):
    """
    Handle 500 errors
    """
    return render_template('error.html', 
                         error_message="Internal server error (500)"), 500


# Run the application
if __name__ == '__main__':
    print("="*60)
    print("🚀 Student Type Prediction Web Application")
    print("="*60)
    print("📊 ML Lab End-Semester Project")
    print("🌐 Starting Flask server...")
    print("="*60)
    
    # Check if model exists
    if not os.path.exists(MODEL_PATH):
        print("\n⚠️  WARNING: Model file not found!")
        print("📝 Please run training_notebook.ipynb first to train and save the model.")
        print("="*60)
    
    # Run Flask app
    # debug=True enables hot reload and detailed error messages
    # Use debug=False in production
    app.run(debug=True, host='0.0.0.0', port=5000)
