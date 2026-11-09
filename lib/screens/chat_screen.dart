import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_colors.dart';
import '../core/app_theme.dart';
import '../core/nav.dart';
import '../data/api_client.dart';
import '../data/repository.dart';
import '../widgets/blue_scaffold.dart';

/// Asistente de ShopMaster (POST /api/chat).
///
/// La tienda sale del token, no se envía. Cada mensaje es independiente: el
/// servidor no guarda el historial de la conversación.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _Mensaje {
  const _Mensaje(this.texto, {required this.delUsuario, this.error = false});

  final String texto;
  final bool delUsuario;
  final bool error;
}

class _ChatScreenState extends State<ChatScreen> {
  static const int _maxCaracteres = 500;
  static const List<String> _sugerencias = [
    '¿Qué productos están agotados?',
    '¿Cuánto vendí hoy?',
  ];

  final _entrada = TextEditingController();
  final _scroll = ScrollController();
  final List<_Mensaje> _mensajes = [
    const _Mensaje(
      '¡Hola! Soy el asistente de ShopMaster. Pregúntame por tus ventas o tu inventario.',
      delUsuario: false,
    ),
  ];
  bool _escribiendo = false;

  @override
  void dispose() {
    _entrada.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _bajar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _enviar([String? sugerido]) async {
    final texto = (sugerido ?? _entrada.text).trim();
    if (texto.isEmpty || _escribiendo) return;

    setState(() {
      _mensajes.add(_Mensaje(texto, delUsuario: true));
      _escribiendo = true;
      _entrada.clear();
    });
    _bajar();

    _Mensaje respuesta;
    try {
      final dicho = await InventarioRepository.instance.chat(texto);
      respuesta = _Mensaje(dicho, delUsuario: false);
    } on ApiException catch (e) {
      respuesta = _Mensaje(e.message, delUsuario: false, error: true);
    }
    if (!mounted) return;
    setState(() {
      _mensajes.add(respuesta);
      _escribiendo = false;
    });
    _bajar();
  }

  @override
  Widget build(BuildContext context) {
    final soloSaludo = _mensajes.length == 1;

    return BlueScaffold(
      title: 'Asistente',
      onBack: () => Nav.volver(context),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              itemCount: _mensajes.length + (_escribiendo ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _mensajes.length) return const _Escribiendo();
                return _Burbuja(_mensajes[i]);
              },
            ),
          ),
          if (soloSaludo)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in _sugerencias)
                    ActionChip(
                      label: Text(s, style: appText(13, color: AppColors.primary)),
                      backgroundColor: AppColors.accentSoft,
                      side: BorderSide.none,
                      onPressed: () => _enviar(s),
                    ),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Container(
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _entrada,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      inputFormatters: [LengthLimitingTextInputFormatter(_maxCaracteres)],
                      style: appText(15),
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        hintText: 'Escribe tu pregunta',
                        hintStyle: appText(15, color: AppColors.placeholder),
                        filled: true,
                        fillColor: AppColors.field,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: const BorderSide(color: AppColors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _escribiendo ? null : _enviar,
                    tooltip: 'Enviar',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.scale2,
                      minimumSize: const Size(48, 48),
                    ),
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Burbuja extends StatelessWidget {
  const _Burbuja(this.mensaje);

  final _Mensaje mensaje;

  @override
  Widget build(BuildContext context) {
    final usuario = mensaje.delUsuario;
    final Color fondo = usuario
        ? AppColors.primary
        : (mensaje.error ? AppColors.dangerBg : AppColors.white);
    final Color texto = usuario
        ? Colors.white
        : (mensaje.error ? AppColors.dangerStrong : AppColors.navy);

    return Align(
      alignment: usuario ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: fondo,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(usuario ? 18 : 4),
              bottomRight: Radius.circular(usuario ? 4 : 18),
            ),
            boxShadow: usuario
                ? null
                : const [BoxShadow(color: Color(0x0F0B2E6B), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Text(mensaje.texto, style: appText(15, color: texto, height: 1.4)),
        ),
      ),
    );
  }
}

class _Escribiendo extends StatelessWidget {
  const _Escribiendo();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(18)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Text('Escribiendo…', style: appText(13, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
