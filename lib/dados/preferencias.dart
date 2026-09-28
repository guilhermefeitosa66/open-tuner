import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../dominio/estado_corda.dart';

/// Tema escolhido nos ajustes.
enum TemaEscolhido { sistema, claro, escuro }

/// Como os nomes das notas aparecem: letras (C D E) ou solfejo (Dó Ré Mi).
enum Notacao { letras, solfejo }

/// Faixa da referência do Lá (A4), em Hz.
const a4Minimo = 430;
const a4Maximo = 450;
const a4Padrao = 440;

/// O que o usuário escolheu, guardado no aparelho (RF-18).
///
/// Lê tudo de uma vez ao abrir; cada escrita vai para o disco sem esperar,
/// porque a tela não depende de a gravação terminar.
class Preferencias {
  Preferencias._(this._disco);

  static Future<Preferencias> carregar() async =>
      Preferencias._(await SharedPreferences.getInstance());

  final SharedPreferences _disco;

  static const _chaveInstrumento = 'instrumento';
  static const _chaveAfinacao = 'afinacao';
  static const _chaveAuto = 'auto';
  static const _chaveCordaFixada = 'cordaFixada';
  static const _chaveTema = 'tema';
  static const _chaveNotacao = 'notacao';
  static const _chavePrecisao = 'precisao';
  static const _chaveA4 = 'a4';
  static const _chaveTelaLigada = 'telaLigada';

  /// Id do instrumento, ou null na primeira abertura.
  String? get instrumento => _disco.getString(_chaveInstrumento);
  set instrumento(String? id) => _gravarTexto(_chaveInstrumento, id);

  /// Id da afinação do instrumento guardado.
  String? get afinacao => _disco.getString(_chaveAfinacao);
  set afinacao(String? id) => _gravarTexto(_chaveAfinacao, id);

  bool get auto => _disco.getBool(_chaveAuto) ?? true;
  set auto(bool valor) => unawaited(_disco.setBool(_chaveAuto, valor));

  /// Corda escolhida à mão, quando o Auto está desligado.
  int get cordaFixada => _disco.getInt(_chaveCordaFixada) ?? 0;
  set cordaFixada(int indice) =>
      unawaited(_disco.setInt(_chaveCordaFixada, indice));

  TemaEscolhido get tema =>
      _lerEnum(TemaEscolhido.values, _chaveTema, TemaEscolhido.sistema);
  set tema(TemaEscolhido valor) => _gravarTexto(_chaveTema, valor.name);

  Notacao get notacao =>
      _lerEnum(Notacao.values, _chaveNotacao, Notacao.letras);
  set notacao(Notacao valor) => _gravarTexto(_chaveNotacao, valor.name);

  Precisao get precisao =>
      _lerEnum(Precisao.values, _chavePrecisao, Precisao.normal);
  set precisao(Precisao valor) => _gravarTexto(_chavePrecisao, valor.name);

  int get a4 =>
      (_disco.getInt(_chaveA4) ?? a4Padrao).clamp(a4Minimo, a4Maximo).toInt();
  set a4(int valor) => unawaited(_disco.setInt(_chaveA4, valor));

  bool get telaLigada => _disco.getBool(_chaveTelaLigada) ?? true;
  set telaLigada(bool valor) =>
      unawaited(_disco.setBool(_chaveTelaLigada, valor));

  T _lerEnum<T extends Enum>(List<T> valores, String chave, T padrao) {
    final nome = _disco.getString(chave);
    for (final valor in valores) {
      if (valor.name == nome) return valor;
    }
    return padrao;
  }

  void _gravarTexto(String chave, String? valor) {
    unawaited(
      valor == null ? _disco.remove(chave) : _disco.setString(chave, valor),
    );
  }
}
