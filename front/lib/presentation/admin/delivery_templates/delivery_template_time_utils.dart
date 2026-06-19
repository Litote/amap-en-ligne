import 'package:flutter/material.dart';

TimeOfDay? parseDeliveryTemplateTime(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final parts = value.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

String formatDeliveryTemplateTime(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

int? deliveryTemplateTimeToMinutes(TimeOfDay? time) =>
    time == null ? null : time.hour * 60 + time.minute;

String? validateStandardEndTime({
  required TimeOfDay? standardStartTime,
  required TimeOfDay? standardEndTime,
}) {
  if (standardEndTime == null) return 'Champ requis.';
  final startMinutes = deliveryTemplateTimeToMinutes(standardStartTime);
  final endMinutes = deliveryTemplateTimeToMinutes(standardEndTime);
  if (startMinutes != null &&
      endMinutes != null &&
      endMinutes <= startMinutes) {
    return "L'heure de fin doit être après l'heure de début.";
  }
  return null;
}

String? validateEarlyArrivalTime({
  required bool hasEarlySlot,
  required TimeOfDay? earlyArrivalTime,
  required TimeOfDay? standardStartTime,
}) {
  if (!hasEarlySlot) return null;
  if (earlyArrivalTime == null) return 'Champ requis.';
  final earlyMinutes = deliveryTemplateTimeToMinutes(earlyArrivalTime);
  final startMinutes = deliveryTemplateTimeToMinutes(standardStartTime);
  if (earlyMinutes != null &&
      startMinutes != null &&
      earlyMinutes >= startMinutes) {
    return "L'arrivée anticipée doit être avant l'heure de début de livraison.";
  }
  return null;
}

String? validateVolunteerArrivalTime({
  required TimeOfDay? volunteerArrivalTime,
  required TimeOfDay? standardStartTime,
}) {
  if (volunteerArrivalTime == null) return null; // field is optional
  final arrivalMinutes = deliveryTemplateTimeToMinutes(volunteerArrivalTime);
  final startMinutes = deliveryTemplateTimeToMinutes(standardStartTime);
  if (arrivalMinutes != null &&
      startMinutes != null &&
      arrivalMinutes > startMinutes) {
    return "L'arrivée des bénévoles doit être avant ou à l'heure de début de livraison.";
  }
  return null;
}
