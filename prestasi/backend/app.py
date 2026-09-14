import os
from flask import Flask, request, jsonify
from werkzeug.utils import secure_filename
import tensorflow as tf
import numpy as np
from PIL import Image

app = Flask(__name__)

# 1. Load Model AI yang sudah kamu latih dari Dataset Kaggle
# (Pastikan kamu sudah menyimpan model hasil training dalam format .h5 atau SavedModel)
MODEL_PATH = "model_garbage_classifier.h5"
if os.path.exists(MODEL_PATH):
    model = tf.keras.models.load_model(MODEL_PATH)
    print("🏆 Model Kaggle berhasil dimuat!")
else:
    model = None
    print("⚠️ Model belum ditemukan, server berjalan dalam mode Simulasi/Mocking.")

# Daftar label sesuai urutan kelas pada dataset Kaggle umumnya
LABELS = ['Cardboard', 'Glass', 'Metal', 'Paper', 'Plastic', 'Trash']

@app.route('/predict', methods=['POST'])
def predict():
    # Validasi file yang masuk dari Flutter
    if 'image' not in request.files:
        return jsonify({'error': 'Tidak ada file gambar yang dikirim'}), 400
    
    file = request.files['image']
    if file.filename == '':
        return jsonify({'error': 'Nama file kosong'}), 400

    if file:
        # Jika model asli belum ada, kita pakai simulasi tebakan acak dulu untuk testing koneksi
        if model is None:
            import random
            pred_class = random.choice(LABELS)
            # Tentukan poin tiruan berdasarkan jenis sampah
            points = 25 if pred_class == 'Plastic' else 15
            return jsonify({
                'status': 'success',
                'detected_item': pred_class,
                'points_awarded': points,
                'message': '[MOCK/SIMULASI] Server terkoneksi dengan baik!'
            })

        # --- LOGIKA ASLI JIKA MODEL .H5 SUDAH ADA ---
        try:
            # Buka dan konversi gambar sesuai input model (misal: 224x224)
            img = Image.open(file.stream).convert('RGB')
            img = img.resize((224, 224)) 
            img_array = np.array(img) / 255.0  # Normalisasi jika saat training di-scale
            img_array = np.expand_dims(img_array, axis=0)

            # Prediksi dengan model TensorFlow
            predictions = model.predict(img_array)
            highest_score_index = np.argmax(predictions[0])
            pred_class = LABELS[highest_score_index]

            # Beri poin dinamis: Plastik & Kaleng biasanya bernilai lebih tinggi
            points = 25 if pred_class in ['Plastic', 'Metal'] else 15

            return jsonify({
                'status': 'success',
                'detected_item': pred_class,
                'points_awarded': points,
                'message': 'Sampah berhasil diidentifikasi via AI'
            })
        except Exception as e:
            return jsonify({'error': f'Gagal memproses gambar: {str(e)}'}), 500

if __name__ == '__main__':
    # Jalankan server di port 5000, host 0.0.0.0 agar bisa diakses HP Oppo A15 lewat satu Wi-Fi
    app.run(host='0.0.0.0', port=5000, debug=True)