// lib/app/core/widgets/custom_text_filed.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    this.controller,
    this.initialValue, 
    this.focusNode,
    this.decoration,
    this.keyboardType,
    this.style = const TextStyle(color: Color(0xff8C8C8C)),
    this.textDirection,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.maxLength,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.clipBehavior = Clip.hardEdge,
    this.fillColor = const Color(0xff181818),
    this.borderRadius = 12.0,
    this.validator,
    this.hintStyle = const TextStyle(
      fontWeight: FontWeight.w300,
      fontSize: 16,
      color: Color(0xff8C8C8C),
    ),
    this.hintText,
    this.enabled = true,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 8,
    ),
    this.borderColor = const Color(0xff3A3A3A),
    this.focusedBorderColor = const Color(0xff3A3A3A),
    this.errorBorderColor = Colors.red,
    this.suffixIcon,
    this.prefixIcon,
    this.obscureText = false,
    this.pprefixIconColor,
    this.items,
    this.value,
    this.inputFormatters,
    this.autovalidateMode = AutovalidateMode.onUserInteraction,
  });
  final AutovalidateMode? autovalidateMode;
  final TextEditingController? controller;
  final String? initialValue;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final TextStyle? style;
  final TextDirection? textDirection;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final Clip clipBehavior;
  final Color fillColor;
  final double borderRadius;
  final FormFieldValidator<String>? validator;
  final TextStyle? hintStyle;
  final String? hintText;
  final bool enabled;
  final EdgeInsetsGeometry contentPadding;
  final Color borderColor;
  final Color focusedBorderColor;
  final Color errorBorderColor;
  final IconData? suffixIcon;
  final IconData? prefixIcon;
  final bool obscureText;
  final Color? pprefixIconColor;

  // Dropdown
  final List<DropdownMenuItem<String>>? items;
  final String? value;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late String? _selectedValue;
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.value ?? widget.initialValue;
    _obscureText = widget.obscureText;
  }

  @override
  void didUpdateWidget(covariant CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _selectedValue = widget.value;
    }
  }

  void _toggleVisibility() => setState(() => _obscureText = !_obscureText);

  InputDecoration _defaultDecoration() {
    return InputDecoration(
      suffixIcon: widget.suffixIcon != null
          ? (widget.obscureText 
                ? IconButton(
                    icon: Icon(
                      _obscureText ? widget.suffixIcon : Icons.remove_red_eye_outlined,
                    ),
                    onPressed: _toggleVisibility,
                  )
                : Icon(widget.suffixIcon, color: const Color(0xff8C8C8C)))
          : (widget.items != null
                ? const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xff8C8C8C),
                  )
                : null),
      prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
      prefixIconColor: widget.pprefixIconColor ?? Colors.white,
      hintText: widget.hintText,
      hintStyle: widget.hintStyle,
      filled: true,
      fillColor: widget.fillColor,
      contentPadding: widget.contentPadding,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        borderSide: BorderSide(color: widget.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        borderSide: BorderSide(color: widget.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        borderSide: BorderSide(color: widget.focusedBorderColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dropdown Mode
    if (widget.items != null && widget.items!.isNotEmpty) {
      return DropdownButtonFormField<String>(
        value: _selectedValue,
        hint: Text(widget.hintText ?? '', style: widget.hintStyle),
        items: widget.items,
        validator: widget.validator,
        onChanged: widget.enabled
            ? (val) {
                setState(() => _selectedValue = val);
                widget.onChanged?.call(val ?? '');
              }
            : null,
        decoration: widget.decoration ?? _defaultDecoration(),
        dropdownColor: widget.fillColor,
        style: widget.style ?? const TextStyle(color: Colors.white),
      );
    }

    // Normal TextField
    return TextFormField(
      autovalidateMode: widget.autovalidateMode,
      controller: widget.controller,
      initialValue: widget.initialValue,
      focusNode: widget.focusNode,
      keyboardType: widget.keyboardType,
      style: widget.style ?? const TextStyle(color: Colors.white),
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      expands: widget.expands,
      obscureText: _obscureText,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      enabled: widget.enabled,
      validator: widget.validator,
      onChanged: widget.onChanged,
      inputFormatters: widget.inputFormatters,
      decoration: widget.decoration ?? _defaultDecoration(),
      clipBehavior: widget.clipBehavior,
    );
  }
}