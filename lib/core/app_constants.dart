import 'package:flutter/material.dart';
import '../models/plant_model.dart';

class AppConstants {
  static const String appName = 'HERBIA';
  static const String tagline = 'Smart Herbal Knowledge at Your Fingertips';
  static const String version = '1.0.0';

  static const double defaultPadding = 16.0;
  static const double cardRadius = 16.0;
  static const double buttonRadius = 12.0;
  static const double textFieldRadius = 12.0;

  static const int splashDuration = 3;

  // Base URL for the Flask API serving the trained herb-relevance model
  // (see api_server.py in the Herbia_model repo). Point this at whatever
  // is reachable from the device/emulator you're testing on:
  //   - Android emulator:      http://10.0.2.2:5000
  //   - iOS simulator:         http://127.0.0.1:5000
  //   - Physical device:       http://<host machine's LAN IP>:5000
  static const String apiBaseUrl = 'http://127.0.0.1:5000';

  static const List<String> categories = [
    'Cough',
    'Fever',
    'Headache',
    'Skin Problems',
    'Stomach Pain',
  ];

  // Unused now that the symptom list is fetched live from the API
  // (196 model-vocabulary symptoms via ApiService.fetchSymptoms(), see
  // SymptomProvider) -- kept here for reference, not read anywhere.
  static const List<Symptom> symptoms = [
    Symptom(id: 'cough', name: 'Cough'),
    Symptom(id: 'fever', name: 'Fever'),
    Symptom(id: 'cold', name: 'Cold'),
    Symptom(id: 'sore-throat', name: 'Sore Throat'),
    Symptom(id: 'headache', name: 'Headache'),
    Symptom(id: 'toothache', name: 'Toothache'),
    Symptom(id: 'stomach-pain', name: 'Stomach Pain'),
    Symptom(id: 'diarrhea', name: 'Diarrhea'),
    Symptom(id: 'skin-rash', name: 'Skin Rash'),
    Symptom(id: 'wounds', name: 'Wounds'),
    Symptom(id: 'body-pain', name: 'Body Pain'),
    Symptom(id: 'high-blood-pressure', name: 'High Blood Pressure'),
    Symptom(id: 'urinary-problems', name: 'Urinary Problems'),
  ];

  static const List<String> filterOptions = [
    'DOH Recognized',
    'Commonly Available',
    'Safe for Children',
    'Safe for Elderly',
    'Easy to Prepare',
  ];
}
