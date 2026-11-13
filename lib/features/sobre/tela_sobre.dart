import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/idioma.dart';
import '../../app/links.dart';
import '../../app/tema.dart';

/// Abre um endereço no navegador do aparelho. O app não tem permissão de
/// internet: quem acessa a rede é o navegador.
typedef AbrirEndereco = Future<void> Function(Uri endereco);

Future<void> _abrirNoNavegador(Uri endereco) async {
  await launchUrl(endereco, mode: LaunchMode.externalApplication);
}

/// A tela Sobre, aberta pelos ajustes: a versão instalada, o site do
/// projeto, a fundação, o código-fonte, a política de privacidade, os termos
/// de uso e as licenças.
class TelaSobre extends StatelessWidget {
  const TelaSobre({
    super.key,
    required this.versao,
    this.abrir = _abrirNoNavegador,
  });

  final String versao;

  /// Trocado nos testes, que não têm navegador.
  final AbrirEndereco abrir;

  @override
  Widget build(BuildContext context) {
    final textos = context.textos;
    final cores = context.cores;
    final idioma = Localizations.localeOf(context).languageCode;

    Widget link(String chave, IconData icone, String rotulo, String endereco) {
      return _Linha(
        chave: chave,
        icone: icone,
        rotulo: rotulo,
        detalhe: Uri.parse(endereco).host,
        externo: true,
        aoTocar: () => abrir(Uri.parse(endereco)),
      );
    }

    return Scaffold(
      backgroundColor: cores.fundo,
      appBar: AppBar(
        backgroundColor: cores.fundo,
        foregroundColor: cores.texto,
        surfaceTintColor: Colors.transparent,
        title: Text(textos.sobreTitulo),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cores.superficie,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OpenTuner',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: cores.texto,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    textos.versaoApp(versao),
                    key: const Key('sobre-versao'),
                    style: TextStyle(
                      fontSize: 14,
                      color: cores.textoSecundario,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    textos.sobreDescricao,
                    style: TextStyle(fontSize: 15, color: cores.texto),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Grupo(
              linhas: [
                link(
                  'sobre-site',
                  Icons.public,
                  textos.linkSite,
                  enderecoSite(idioma),
                ),
                link(
                  'sobre-fundacao',
                  Icons.volunteer_activism_outlined,
                  textos.linkFundacao,
                  enderecoFundacao,
                ),
                link(
                  'sobre-codigo',
                  Icons.code,
                  textos.linkCodigo,
                  enderecoCodigo,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Grupo(
              linhas: [
                link(
                  'sobre-privacidade',
                  Icons.privacy_tip_outlined,
                  textos.linkPrivacidade,
                  enderecoPrivacidade(idioma),
                ),
                link(
                  'sobre-termos',
                  Icons.gavel_outlined,
                  textos.linkTermos,
                  enderecoTermos(idioma),
                ),
                _Linha(
                  chave: 'sobre-licencas',
                  icone: Icons.description_outlined,
                  rotulo: textos.linkLicencas,
                  detalhe: 'Apache 2.0',
                  externo: false,
                  aoTocar: () => showLicensePage(
                    context: context,
                    applicationName: 'OpenTuner',
                    applicationVersion: versao,
                    applicationLegalese: 'Apache-2.0',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Grupo extends StatelessWidget {
  const _Grupo({required this.linhas});

  final List<Widget> linhas;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return Material(
      color: cores.superficie,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < linhas.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 56, color: cores.grade),
            linhas[i],
          ],
        ],
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({
    required this.chave,
    required this.icone,
    required this.rotulo,
    required this.detalhe,
    required this.externo,
    required this.aoTocar,
  });

  final String chave;
  final IconData icone;
  final String rotulo;
  final String detalhe;
  final bool externo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final cores = context.cores;
    return Semantics(
      link: externo,
      button: !externo,
      child: ListTile(
        key: Key(chave),
        minTileHeight: 56,
        leading: Icon(icone, color: cores.accent),
        title: Text(
          rotulo,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: cores.texto,
          ),
        ),
        subtitle: Text(
          detalhe,
          style: TextStyle(fontSize: 13, color: cores.textoSecundario),
        ),
        trailing: Icon(
          externo ? Icons.open_in_new : Icons.chevron_right,
          size: 20,
          color: cores.textoSecundario,
        ),
        onTap: aoTocar,
      ),
    );
  }
}
