import 'package:encrypted_shared_preferences/encrypted_shared_preferences.dart';
import 'package:flutter/cupertino.dart';

import 'VehicleMaintenanceDAO.dart';

class VehicleMaintenanceDataRepository {
  static VehicleMaintenanceDAO? myDAO;
  static var list;
  static String button = "Add";
  static int id = -1;
  static EncryptedSharedPreferences esp = EncryptedSharedPreferences();

  static void getData(String key) {
    esp.getString(key).then((String value) {
      key = value;
    });
  }

  static void loadData(String key, TextEditingController controller) {
    esp.getString(key).then((String value){
      controller.text = value;
    });
  }

  static void saveData(String key, String value) {
    esp.setString(key, value).then((bool success) {
      if (success)
        print(key + ' was successfully saved');
      else
        print(key + ' was unsuccessfully saved');
    });
  }
}