import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/theme.dart';

/// AppInput - Reusable input field component for FitLife app
/// Supports clean minimal style with white background and light gray borders
class AppInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool obscureText;
  final bool isPassword; // New parameter for password fields with visibility toggle
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final FocusNode? focusNode;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final bool useCleanStyle; // New parameter to switch between styles

  const AppInput({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.isPassword = false, // New parameter
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.useCleanStyle = true, // Default to clean style
  });

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _obscureText = true; // For password visibility toggle

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    _obscureText = widget.obscureText || widget.isPassword; // Start obscured for password fields
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.useCleanStyle) {
      // Clean minimal style using theme's InputDecorationTheme
      return TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        obscureText: widget.isPassword ? _obscureText : widget.obscureText,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        textInputAction: widget.textInputAction,
        validator: widget.validator,
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onSubmitted,
        enabled: widget.enabled,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        style: FitLifeTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: widget.hintText,
          labelText: widget.labelText,
          helperText: '', // Reserve space for error messages to prevent layout shift
          errorStyle: FitLifeTheme.bodySmall.copyWith(
            color: FitLifeTheme.highlightPink, // Use pink for errors to match neon theme
            fontSize: 10, // Smaller error text
          ),
          prefixIcon: widget.prefixIcon != null
              ? Icon(
                  widget.prefixIcon,
                  color: _isFocused ? FitLifeTheme.accentGreen : FitLifeTheme.primaryText.withOpacity(0.6),
                )
              : null,
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: _isFocused ? FitLifeTheme.accentGreen : FitLifeTheme.primaryText.withOpacity(0.6),
                  ),
                  onPressed: _togglePasswordVisibility,
                )
              : (widget.suffixIcon != null
                  ? Icon(
                      widget.suffixIcon,
                      color: _isFocused ? FitLifeTheme.accentGreen : FitLifeTheme.primaryText.withOpacity(0.6),
                    )
                  : null),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: FitLifeTheme.spacingM,
            vertical: FitLifeTheme.spacingS, // Reduced from spacingM to spacingS for compact inputs while maintaining touch-friendliness
          ),
        ),
      );
    } else {
      // Legacy style
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: FitLifeTheme.inputFillColor, // Dark fill for inputs
          borderRadius: BorderRadius.circular(FitLifeTheme.inputBorderRadius),
          boxShadow: [FitLifeTheme.inputShadow],
          border: _isFocused
              ? Border.all(color: FitLifeTheme.focusBorderColor, width: 2) // Accent gray for focus
              : Border.all(color: FitLifeTheme.borderColor, width: 1), // Gray border normally
        ),
        child: TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: widget.isPassword ? _obscureText : widget.obscureText,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          enabled: widget.enabled,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          style: FitLifeTheme.bodyLarge.copyWith(color: FitLifeTheme.textPrimary), // Use new text color
          decoration: InputDecoration(
            hintText: widget.hintText,
            labelText: widget.labelText,
            helperText: '', // Reserve space for error messages to prevent layout shift
            errorStyle: FitLifeTheme.bodySmall.copyWith(
              color: FitLifeTheme.highlightPink, // Use pink for errors to match neon theme
              fontSize: 10, // Smaller error text
            ),
            labelStyle: FitLifeTheme.bodyMedium.copyWith(
              color: _isFocused ? FitLifeTheme.accentGray : FitLifeTheme.textSecondary, // Use accent gray for focus
            ),
            hintStyle: FitLifeTheme.bodyMedium.copyWith(
              color: FitLifeTheme.textSecondary.withValues(alpha: 0.6),
            ),
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: _isFocused ? FitLifeTheme.accentGray : FitLifeTheme.textSecondary, // Use accent gray for focus
                  )
                : null,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: _isFocused ? FitLifeTheme.accentGray : FitLifeTheme.textSecondary, // Use accent gray for focus
                    ),
                    onPressed: _togglePasswordVisibility,
                  )
                : (widget.suffixIcon != null
                    ? Icon(
                        widget.suffixIcon,
                        color: _isFocused ? FitLifeTheme.accentGray : FitLifeTheme.textSecondary, // Use accent gray for focus
                      )
                    : null),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: FitLifeTheme.spacingM,
              vertical: FitLifeTheme.spacingS, // Reduced from spacingM to spacingS for compact inputs while maintaining touch-friendliness
            ),
          ),
        ),
      );
    }
  }
}