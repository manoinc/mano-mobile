import 'package:flutter/material.dart';
import 'package:mano_ui/mano_ui.dart';
import 'package:widgetbook/widgetbook.dart';

import 'sample.dart';

WidgetbookCategory overlays() => WidgetbookCategory(
  name: 'Overlays',
  children: [
    component('ManoDialogCard', {
      'Inline': (context) => const Center(child: _Dialog()),
      'Open with showManoDialog': (context) => _Launcher(
        label: 'Abrir diálogo',
        open: (c) => showManoDialog<void>(context: c, builder: (_) => const _Dialog()),
      ),
    }),
    component('ManoPromptSheet', {
      'Inline': (context) => const Align(alignment: Alignment.bottomCenter, child: _Prompt()),
      'Open with showManoSheet': (context) => _Launcher(
        label: 'Abrir hoja',
        open: (c) => showManoSheet<void>(context: c, builder: (_) => const _Prompt()),
      ),
    }),
    component('ManoAccountNeededSheet', {
      'Inline': (context) => const Align(alignment: Alignment.bottomCenter, child: _AccountNeeded()),
      'Open with showManoSheet': (context) => _Launcher(
        label: 'Aceptar solicitud',
        open: (c) => showManoSheet<void>(context: c, builder: (_) => const _AccountNeeded()),
      ),
    }),
    component('ManoCredentialsSheet', {
      'Inline': (context) => const Align(alignment: Alignment.bottomCenter, child: _Credentials()),
      'Open with showManoSheet': (context) => _Launcher(
        label: 'Iniciar sesión',
        open: (c) => showManoSheet<void>(context: c, builder: (_) => const _Credentials()),
      ),
    }),
    component('ManoActionSheet', {
      'Inline': (context) => const Align(alignment: Alignment.bottomCenter, child: _Actions()),
      'Open with showManoSheet': (context) => _Launcher(
        label: 'Abrir acciones',
        open: (c) => showManoSheet<void>(context: c, builder: (_) => const _Actions()),
      ),
    }),
    component('ManoMediaSourceSheet', {
      'Inline': (context) => const Align(
        alignment: Alignment.bottomCenter,
        child: ManoMediaSourceSheet(onGallery: noop, onCamera: noop, onClose: noop),
      ),
    }),
    component('ManoOptionRow', {
      'Default': (context) => const ManoOptionRow(
        label: 'Notificaciones',
        icon: Icons.notifications_outlined,
        detail: 'Activadas',
        onPressed: noop,
      ),
      'Destructive': (context) => const ManoOptionRow(
        label: 'Cerrar sesión',
        icon: Icons.logout,
        destructive: true,
        onPressed: noop,
      ),
    }),
  ],
);

class _Dialog extends StatelessWidget {
  const _Dialog();

  @override
  Widget build(BuildContext context) => const ManoDialogCard(
    title: '¿Cancelar este trabajo?',
    message: 'Le avisaremos al profesional.',
    primaryLabel: 'Sí, cancelar',
    onPrimary: noop,
  );
}

class _Prompt extends StatelessWidget {
  const _Prompt();

  @override
  Widget build(BuildContext context) => const ManoPromptSheet(
    title: 'Necesitas una cuenta',
    message: 'Inicia sesión para agendar con este profesional.',
    primaryLabel: 'Iniciar sesión',
    onPrimary: noop,
    onClose: noop,
  );
}

class _AccountNeeded extends StatelessWidget {
  const _AccountNeeded();

  @override
  Widget build(BuildContext context) => const ManoAccountNeededSheet(
    message: 'Inicia sesión para aceptar solicitudes.',
    onSignIn: noop,
    onClose: noop,
  );
}

class _Credentials extends StatelessWidget {
  const _Credentials();

  @override
  Widget build(BuildContext context) => ManoCredentialsSheet(
    title: 'Inicia sesión',
    message: 'Con el correo de tu cuenta Mano.',
    submitLabel: 'Entrar',
    onSubmit: (_, _) async => 'Correo o contraseña incorrectos',
  );
}

class _Actions extends StatelessWidget {
  const _Actions();

  @override
  Widget build(BuildContext context) => const ManoActionSheet(
    title: '¿Qué quieres hacer?',
    actions: [
      ManoSheetAction(label: 'Publicar un trabajo', icon: Icons.add_task, onPressed: noop),
      ManoSheetAction(label: 'Buscar un servicio', icon: Icons.search, detail: 'Explora el catálogo', onPressed: noop),
    ],
    onClose: noop,
  );
}

class _Launcher extends StatelessWidget {
  const _Launcher({required this.label, required this.open});

  final String label;
  final void Function(BuildContext context) open;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(ManoSpacing.lg),
      child: ManoOutlineButton(label: label, onPressed: () => open(context)),
    ),
  );
}
