import firebase_admin
from firebase_admin import credentials, firestore
import pandas as pd


cred = credentials.Certificate("projet-fin-etude-69d11-firebase-adminsdk-fbsvc-a6ad99b435.json")
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)
db = firestore.client()

def import_from_organized_excel():
    file_path = "students.xlsx"  
    try:
        
        print("Step 1: Processing Teachers & Creating Unique Subjects...")
        df_teachers = pd.read_excel(file_path, sheet_name='teacher', dtype=str)
        df_teachers.columns = [c.strip().lower() for c in df_teachers.columns]

        for index, row in df_teachers.iterrows():
            reg_num = str(row.get('registrationnumber', '')).split('.')[0].strip()
            if not reg_num or reg_num.lower() == "nan": continue

            
            db.collection('users').document(reg_num).set({
                'registrationNumber': reg_num,
                'firstName': str(row.get('firstname', '')).strip(),
                'lastName': str(row.get('lastname', '')).strip(),
                'role': 'teacher',
                'password': str(row.get('password', '123456')).strip(),
            }, merge=True)

            
            subject_raw = str(row.get('subjects', '')).strip()
            if subject_raw:
                subjects_list = [s.strip() for s in subject_raw.split(',')]
                for sub_name in subjects_list:
                    clean_sub_name = sub_name.replace(" ", "_").lower()
                    
                    sub_id = f"{clean_sub_name}_{reg_num}" 
                    
                    db.collection('subjects').document(sub_id).set({
                        'name': sub_name,
                        'teacherId': reg_num,
                        'originalCode': clean_sub_name
                    }, merge=True)

        
        print("\nStep 2: Processing Students & Linking to Specific Teachers...")
        df_students = pd.read_excel(file_path, sheet_name='students', dtype=str)
        df_students.columns = [c.strip().lower() for c in df_students.columns]

        for index, row in df_students.iterrows():
            reg_num = str(row.get('registrationnumber', '')).split('.')[0].strip()
            if not reg_num or reg_num.lower() == "nan": continue

            group_id = str(row.get('group', 'group1')).strip()
            year = str(row.get('year', 'L3')).strip()
            full_name = f"{str(row.get('firstname')).strip()} {str(row.get('lastname')).strip()}"
            
            
            teachers_raw = str(row.get('teacherid', '')).strip()
            
            
            db.collection('users').document(reg_num).set({
                'registrationNumber': reg_num,
                'firstName': str(row.get('firstname', '')).strip(),
                'lastName': str(row.get('lastname', '')).strip(),
                'role': 'student',
                'password': str(row.get('password', '123456')).strip(),
                'year': year,
            }, merge=True)

            subject_raw = str(row.get('subjects', '')).strip()
            if subject_raw and teachers_raw:
                
                subjects_list = [s.strip() for s in subject_raw.split(',')]
                teachers_list = [t.strip() for t in teachers_raw.split(',')]

                for sub_name in subjects_list:
                    clean_sub_name = sub_name.replace(" ", "_").lower()
                    
                    
                    for t_id in teachers_list:
                        actual_sub_id = f"{clean_sub_name}_{t_id}"
                        
                        
                        sub_ref = db.collection('subjects').document(actual_sub_id)
                        if sub_ref.get().exists:
                            
                            sub_ref.collection('groups').document(group_id).set({
                                'groupName': group_id,
                                'subjectId': actual_sub_id,
                                'teacherId': t_id
                            }, merge=True)

                            
                            sub_ref.collection('groups').document(group_id)\
                                   .collection('students').document(reg_num).set({
                                'registrationNumber': reg_num,
                                'name': full_name,
                                'status': 'absent'
                            }, merge=True)

        print("\n Database is perfectly organized! Each teacher will now see ONLY their students.")

    except Exception as e:
        print(f" Error: {e}")

if __name__ == "__main__":
    import_from_organized_excel()