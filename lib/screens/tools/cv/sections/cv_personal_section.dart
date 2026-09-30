import 'package:flutter/material.dart';

import '../cv_form_state.dart';
import '../cv_section_meta.dart';
import '../widgets/cv_fields.dart';
import '../widgets/cv_photo_picker.dart';

/// Photo, name, role, contact and bio-data details.
class CvPersonalSection extends StatelessWidget {
  final CvFormState form;
  final VoidCallback onChanged;

  const CvPersonalSection({
    super.key,
    required this.form,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final meta = kCvSections[0];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      children: [
        CvSectionHeader(
          heading: meta.heading,
          subtitle: meta.subtitle,
          icon: meta.icon,
          color: meta.color,
          gradient: meta.gradient,
          done: form.isSectionDone(0),
        ),
        CvPhotoPicker(
          photo: form.photo,
          onPhoto: (bytes) {
            form.photo = bytes;
            onChanged();
          },
        ),
        const SizedBox(height: 14),
        CvInputField(
          controller: form.name,
          label: 'Full Name *',
          hint: 'e.g. Keshab Sarkar',
          icon: Icons.badge_outlined,
          onChanged: (_) => onChanged(),
        ),
        CvInputField(
          controller: form.title,
          label: 'Professional Title',
          hint: 'e.g. Software Engineer',
          icon: Icons.work_outline_rounded,
          onChanged: (_) => onChanged(),
        ),
        CvInputField(
          controller: form.email,
          label: 'Email *',
          hint: 'keshabsarkar2018@gmail.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => onChanged(),
        ),
        CvInputField(
          controller: form.phone,
          label: 'Mobile *',
          hint: '+91 9382284190',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          onChanged: (_) => onChanged(),
        ),
        CvInputField(
          controller: form.address,
          label: 'Address',
          hint:
              'Simla, Mertala, Tita, Purbasthali-2 Block, Purba Bardhaman - 713513',
          icon: Icons.location_on_outlined,
          maxLines: 2,
          onChanged: (_) => onChanged(),
        ),
        Row(
          children: [
            Expanded(
              child: CvInputField(
                controller: form.dob,
                label: 'DOB',
                hint: '25/07/1997',
                icon: Icons.cake_outlined,
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CvInputField(
                controller: form.father,
                label: "Father's Name",
                hint: 'Krishna Sarkar',
                icon: Icons.family_restroom_outlined,
                onChanged: (_) => onChanged(),
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: CvInputField(
                controller: form.mother,
                label: "Mother's Name",
                hint: 'Full name',
                icon: Icons.family_restroom_outlined,
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CvInputField(
                controller: form.nationality,
                label: 'Nationality',
                hint: 'Indian',
                icon: Icons.flag_outlined,
                onChanged: (_) => onChanged(),
              ),
            ),
          ],
        ),
        CvChoiceChips(
          title: 'Gender',
          options: const ['Male', 'Female', 'Other'],
          controller: form.gender,
          onChanged: onChanged,
        ),
        CvChoiceChips(
          title: 'Marital Status',
          options: const ['Unmarried', 'Married', 'Divorced', 'Widowed'],
          controller: form.maritalStatus,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
