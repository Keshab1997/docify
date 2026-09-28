import 'package:flutter/material.dart';

import '../../../../models/cv_template_info.dart';

class CvTemplateThumbnail extends StatelessWidget {
  final CvTemplateInfo template;
  final bool isSelected;
  final bool enlarged;

  const CvTemplateThumbnail({
    super.key,
    required this.template,
    required this.isSelected,
    this.enlarged = false,
  });

  @override
  Widget build(BuildContext context) {
    final w = enlarged ? 72.0 : 42.0;
    final h = enlarged ? 92.0 : 54.0;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(enlarged ? 8 : 4),
        border: Border.all(
          color: isSelected ? template.accentColor : Colors.grey.shade300,
          width: isSelected ? 1.5 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 3,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildLayout(),
    );
  }

  Widget _buildLayout() {
    switch (template.id) {
      case 0:
        return Row(
          children: [
            Container(width: enlarged ? 22 : 13, color: template.primaryColor),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(enlarged ? 4 : 2.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: enlarged ? 5 : 3,
                      width: enlarged ? 30 : 18,
                      color: template.primaryColor,
                    ),
                    SizedBox(height: enlarged ? 3 : 2),
                    Container(
                      height: 1.5,
                      width: enlarged ? 36 : 22,
                      color: Colors.grey.shade300,
                    ),
                    SizedBox(height: enlarged ? 3 : 2),
                    Container(
                      height: 1.5,
                      width: enlarged ? 26 : 16,
                      color: Colors.grey.shade300,
                    ),
                    SizedBox(height: enlarged ? 4 : 3),
                    Container(
                      height: enlarged ? 3 : 2,
                      width: enlarged ? 20 : 12,
                      color: template.accentColor,
                    ),
                    SizedBox(height: enlarged ? 3 : 2),
                    Container(
                      height: 1.5,
                      width: enlarged ? 34 : 20,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case 1:
        return Column(
          children: [
            Container(
              height: enlarged ? 22 : 13,
              color: template.primaryColor,
              padding: EdgeInsets.all(enlarged ? 4 : 2),
              alignment: Alignment.centerLeft,
              child: Container(
                height: enlarged ? 3 : 2,
                width: enlarged ? 26 : 16,
                color: template.accentColor,
              ),
            ),
            Container(height: 1.5, color: template.accentColor),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(enlarged ? 4 : 2.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: enlarged ? 3 : 2,
                      width: enlarged ? 24 : 14,
                      color: template.primaryColor,
                    ),
                    SizedBox(height: enlarged ? 3 : 2),
                    Container(
                      height: 1.5,
                      width: enlarged ? 48 : 28,
                      color: Colors.grey.shade300,
                    ),
                    SizedBox(height: enlarged ? 4 : 3),
                    Container(
                      height: enlarged ? 3 : 2,
                      width: enlarged ? 26 : 16,
                      color: template.primaryColor,
                    ),
                    SizedBox(height: enlarged ? 3 : 2),
                    Container(
                      height: 1.5,
                      width: enlarged ? 40 : 24,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case 2:
        return Padding(
          padding: EdgeInsets.all(enlarged ? 4 : 2.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: enlarged ? 8 : 5,
                    height: enlarged ? 8 : 5,
                    color: template.primaryColor,
                  ),
                  SizedBox(width: enlarged ? 3 : 2),
                  Container(
                    height: enlarged ? 4 : 2.5,
                    width: enlarged ? 26 : 16,
                    color: template.primaryColor,
                  ),
                ],
              ),
              SizedBox(height: enlarged ? 3 : 2),
              Row(
                children: [
                  Container(
                    height: enlarged ? 3 : 2,
                    width: enlarged ? 10 : 6,
                    color: template.accentColor.withValues(alpha: 0.5),
                  ),
                  SizedBox(width: enlarged ? 3 : 2),
                  Container(
                    height: enlarged ? 3 : 2,
                    width: enlarged ? 14 : 8,
                    color: template.accentColor.withValues(alpha: 0.5),
                  ),
                  SizedBox(width: enlarged ? 3 : 2),
                  Container(
                    height: enlarged ? 3 : 2,
                    width: enlarged ? 10 : 6,
                    color: template.accentColor.withValues(alpha: 0.5),
                  ),
                ],
              ),
              SizedBox(height: enlarged ? 4 : 3),
              Container(
                height: 1.5,
                width: enlarged ? 46 : 28,
                color: Colors.grey.shade300,
              ),
              SizedBox(height: enlarged ? 3 : 2),
              Container(
                height: 1.5,
                width: enlarged ? 36 : 22,
                color: Colors.grey.shade300,
              ),
              SizedBox(height: enlarged ? 4 : 3),
              Container(
                height: enlarged ? 3 : 2,
                width: enlarged ? 20 : 12,
                color: template.primaryColor,
              ),
              SizedBox(height: enlarged ? 3 : 2),
              Container(
                height: 1.5,
                width: enlarged ? 44 : 26,
                color: Colors.grey.shade300,
              ),
            ],
          ),
        );
      case 3:
        return Column(
          children: [
            Container(
              height: enlarged ? 24 : 14,
              color: template.primaryColor,
              padding: EdgeInsets.all(enlarged ? 4 : 2),
              child: Row(
                children: [
                  Container(
                    width: enlarged ? 12 : 7,
                    height: enlarged ? 12 : 7,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: enlarged ? 3 : 2),
                  Container(
                    height: enlarged ? 3 : 2,
                    width: enlarged ? 24 : 14,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(enlarged ? 4 : 2.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: enlarged ? 3 : 2,
                      width: enlarged ? 20 : 12,
                      color: template.accentColor,
                    ),
                    SizedBox(height: enlarged ? 3 : 2),
                    Container(
                      height: 1.5,
                      width: enlarged ? 44 : 26,
                      color: Colors.grey.shade300,
                    ),
                    SizedBox(height: enlarged ? 4 : 3),
                    Container(
                      height: enlarged ? 3 : 2,
                      width: enlarged ? 24 : 14,
                      color: template.accentColor,
                    ),
                    SizedBox(height: enlarged ? 3 : 2),
                    Container(
                      height: 1.5,
                      width: enlarged ? 36 : 22,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case 4:
        return Padding(
          padding: EdgeInsets.all(enlarged ? 4 : 2),
          child: Column(
            children: [
              Center(
                child: Container(
                  height: enlarged ? 3 : 2,
                  width: enlarged ? 30 : 18,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: enlarged ? 3 : 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 1.5,
                        width: enlarged ? 20 : 12,
                        color: Colors.black,
                      ),
                      SizedBox(height: enlarged ? 2 : 1),
                      Container(
                        height: 1,
                        width: enlarged ? 26 : 16,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                  Container(
                    width: enlarged ? 12 : 7,
                    height: enlarged ? 16 : 9,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 0.5),
                    ),
                  ),
                ],
              ),
              SizedBox(height: enlarged ? 3 : 2),
              Container(height: 0.5, color: Colors.black),
              SizedBox(height: enlarged ? 3 : 2),
              Container(
                height: enlarged ? 20 : 12,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400, width: 0.5),
                ),
                child: Column(
                  children: [
                    Container(
                      height: enlarged ? 4 : 2.5,
                      color: Colors.grey.shade200,
                    ),
                    const Spacer(),
                    Container(height: 0.5, color: Colors.grey.shade300),
                    const Spacer(),
                  ],
                ),
              ),
            ],
          ),
        );
      case 5:
        return Padding(
          padding: EdgeInsets.all(enlarged ? 5 : 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: enlarged ? 5 : 3,
                width: enlarged ? 30 : 18,
                color: Colors.black,
              ),
              SizedBox(height: enlarged ? 3 : 2),
              Container(
                height: 0.8,
                width: enlarged ? 44 : 26,
                color: Colors.grey.shade600,
              ),
              SizedBox(height: enlarged ? 3 : 2),
              Container(height: 0.8, color: Colors.black),
              SizedBox(height: enlarged ? 3 : 2),
              Container(
                height: 1.5,
                width: enlarged ? 24 : 14,
                color: Colors.black,
              ),
              SizedBox(height: enlarged ? 2 : 1.5),
              Container(
                height: 1,
                width: enlarged ? 40 : 24,
                color: Colors.grey.shade400,
              ),
              SizedBox(height: enlarged ? 3 : 2),
              Container(
                height: 1.5,
                width: enlarged ? 26 : 16,
                color: Colors.black,
              ),
              SizedBox(height: enlarged ? 2 : 1.5),
              Container(
                height: 1,
                width: enlarged ? 36 : 22,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        );
      case 6:
        return Column(
          children: [
            Container(height: enlarged ? 24 : 14, color: template.primaryColor),
            Container(height: 1.5, color: template.accentColor),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(enlarged ? 4 : 2.5),
                child: Row(
                  children: [
                    Container(
                      width: enlarged ? 18 : 10,
                      color: Colors.grey.shade100,
                    ),
                    SizedBox(width: enlarged ? 4 : 3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: enlarged ? 3 : 2,
                            width: enlarged ? 20 : 12,
                            color: template.primaryColor,
                          ),
                          SizedBox(height: enlarged ? 2 : 1.5),
                          Container(
                            height: 1.2,
                            width: enlarged ? 26 : 16,
                            color: Colors.grey.shade300,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case 7:
        return Row(
          children: [
            Container(width: enlarged ? 5 : 3, color: template.primaryColor),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(enlarged ? 4 : 2.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: enlarged ? 4 : 2.5,
                      width: enlarged ? 26 : 16,
                      color: template.primaryColor,
                    ),
                    SizedBox(height: enlarged ? 2 : 1.5),
                    Container(height: 0.8, color: template.primaryColor),
                    SizedBox(height: enlarged ? 3 : 2),
                    Container(
                      height: enlarged ? 10 : 6,
                      decoration: BoxDecoration(
                        color: template.accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                    SizedBox(height: enlarged ? 3 : 2),
                    Container(
                      height: 1.2,
                      width: enlarged ? 36 : 22,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case 8:
        return Row(
          children: [
            Container(
              width: enlarged ? 22 : 13,
              color: const Color(0xFFF1F5F9),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(enlarged ? 4 : 2.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: enlarged ? 4 : 2.5,
                      width: enlarged ? 26 : 16,
                      color: template.primaryColor,
                    ),
                    SizedBox(height: enlarged ? 2 : 1.5),
                    Container(
                      height: 1,
                      width: enlarged ? 30 : 18,
                      color: template.accentColor,
                    ),
                    SizedBox(height: enlarged ? 3 : 2),
                    Container(
                      height: 1.2,
                      width: enlarged ? 26 : 16,
                      color: Colors.grey.shade300,
                    ),
                    SizedBox(height: enlarged ? 2 : 1.5),
                    Container(
                      height: 1.2,
                      width: enlarged ? 24 : 14,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case 9:
      default:
        return Padding(
          padding: EdgeInsets.all(enlarged ? 4 : 2.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: enlarged ? 8 : 5,
                    height: enlarged ? 8 : 5,
                    decoration: BoxDecoration(
                      color: template.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: enlarged ? 3 : 2),
                  Container(
                    height: enlarged ? 4 : 2.5,
                    width: enlarged ? 26 : 16,
                    color: Colors.grey.shade800,
                  ),
                ],
              ),
              SizedBox(height: enlarged ? 3 : 2),
              Container(height: 1, color: template.accentColor),
              SizedBox(height: enlarged ? 3 : 2),
              Container(
                height: 1.5,
                width: enlarged ? 24 : 14,
                color: template.primaryColor,
              ),
              SizedBox(height: enlarged ? 2 : 1.5),
              Container(
                height: 1.2,
                width: enlarged ? 40 : 24,
                color: Colors.grey.shade300,
              ),
              SizedBox(height: enlarged ? 3 : 2),
              Container(
                height: 1.5,
                width: enlarged ? 20 : 12,
                color: template.primaryColor,
              ),
              SizedBox(height: enlarged ? 2 : 1.5),
              Container(
                height: 1.2,
                width: enlarged ? 34 : 20,
                color: Colors.grey.shade300,
              ),
            ],
          ),
        );
    }
  }
}
