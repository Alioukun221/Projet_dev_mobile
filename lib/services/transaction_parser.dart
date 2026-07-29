import 'package:spendwise/models/parsed_transaction.dart';

class TransactionParser {
  static const String wavePackage = 'com.wave.personal';
  static const String orangeMoneyPackage = 'com.orange.myorange.osn';

  static ParsedTransaction? parse({
    required String packageName,
    required String title,
    required String content,
  }) {
    if (packageName == wavePackage) {
      return _parseWave(title, content);
    } else if (packageName == orangeMoneyPackage) {
      return _parseOrangeMoney(title, content);
    }
    return null;
  }

  static ParsedTransaction? _parseWave(String title, String content) {
    final text = '$title $content'.toLowerCase();

    // Received money: "Vous avez recu 5 000 FCFA de ..."
    final recuMatch = RegExp(
      r'(?:re[cç]u|received)\s+([\d\s.,]+)\s*(?:f(?:\s*cfa)?|xof)',
      caseSensitive: false,
    ).firstMatch(text);
    if (recuMatch != null) {
      final amount = _parseAmount(recuMatch.group(1)!);
      if (amount != null && amount > 0) {
        return ParsedTransaction(
          type: 'deposit',
          amount: amount,
          description: _cleanDescription(content, 'Wave'),
          source: 'wave',
          rawTitle: title,
          rawContent: content,
          date: DateTime.now(),
        );
      }
    }

    // Sent money: "Vous avez envoye 5 000 FCFA a ..."
    final envoyeMatch = RegExp(
      r'(?:envoy[eé]|sent|transfer)\s+([\d\s.,]+)\s*(?:f(?:\s*cfa)?|xof)',
      caseSensitive: false,
    ).firstMatch(text);
    if (envoyeMatch != null) {
      final amount = _parseAmount(envoyeMatch.group(1)!);
      if (amount != null && amount > 0) {
        return ParsedTransaction(
          type: 'withdrawal',
          amount: amount,
          description: _cleanDescription(content, 'Wave'),
          source: 'wave',
          rawTitle: title,
          rawContent: content,
          date: DateTime.now(),
        );
      }
    }

    // Payment: "Paiement de 5 000 FCFA chez ..."
    final paiementMatch = RegExp(
      r'(?:paiement|payment|pay[eé])\s+(?:de\s+)?([\d\s.,]+)\s*(?:f(?:\s*cfa)?|xof)',
      caseSensitive: false,
    ).firstMatch(text);
    if (paiementMatch != null) {
      final amount = _parseAmount(paiementMatch.group(1)!);
      if (amount != null && amount > 0) {
        return ParsedTransaction(
          type: 'withdrawal',
          amount: amount,
          description: _cleanDescription(content, 'Wave'),
          source: 'wave',
          rawTitle: title,
          rawContent: content,
          date: DateTime.now(),
        );
      }
    }

    // Deposit: "Depot de 5 000 FCFA"
    final depotMatch = RegExp(
      r'(?:d[eé]p[oô]t|deposit)\s+(?:de\s+)?([\d\s.,]+)\s*(?:f(?:\s*cfa)?|xof)',
      caseSensitive: false,
    ).firstMatch(text);
    if (depotMatch != null) {
      final amount = _parseAmount(depotMatch.group(1)!);
      if (amount != null && amount > 0) {
        return ParsedTransaction(
          type: 'deposit',
          amount: amount,
          description: _cleanDescription(content, 'Wave'),
          source: 'wave',
          rawTitle: title,
          rawContent: content,
          date: DateTime.now(),
        );
      }
    }

    // Withdrawal: "Retrait de 5 000 FCFA"
    final retraitMatch = RegExp(
      r'(?:retrait|withdrawal|retire)\s+(?:de\s+)?([\d\s.,]+)\s*(?:f(?:\s*cfa)?|xof)',
      caseSensitive: false,
    ).firstMatch(text);
    if (retraitMatch != null) {
      final amount = _parseAmount(retraitMatch.group(1)!);
      if (amount != null && amount > 0) {
        return ParsedTransaction(
          type: 'withdrawal',
          amount: amount,
          description: _cleanDescription(content, 'Wave'),
          source: 'wave',
          rawTitle: title,
          rawContent: content,
          date: DateTime.now(),
        );
      }
    }

    // Fallback: generic FCFA amount detection
    return _tryGenericParse(title, content, 'wave');
  }

  static ParsedTransaction? _parseOrangeMoney(String title, String content) {
    final text = '$title $content'.toLowerCase();

    // Received transfer: "Transfert recu de 5 000 FCFA"
    final recuMatch = RegExp(
      r'(?:transfert\s+re[cç]u|re[cç]u|received|cr[eé]dit[eé])\s+(?:de\s+)?([\d\s.,]+)\s*(?:f(?:\s*cfa)?|xof)',
      caseSensitive: false,
    ).firstMatch(text);
    if (recuMatch != null) {
      final amount = _parseAmount(recuMatch.group(1)!);
      if (amount != null && amount > 0) {
        return ParsedTransaction(
          type: 'deposit',
          amount: amount,
          description: _cleanDescription(content, 'Orange Money'),
          source: 'orange_money',
          rawTitle: title,
          rawContent: content,
          date: DateTime.now(),
        );
      }
    }

    // Deposit: "Depot de 5 000 FCFA"
    final depotMatch = RegExp(
      r'(?:d[eé]p[oô]t|deposit|rechargement)\s+(?:de\s+)?([\d\s.,]+)\s*(?:f(?:\s*cfa)?|xof)',
      caseSensitive: false,
    ).firstMatch(text);
    if (depotMatch != null) {
      final amount = _parseAmount(depotMatch.group(1)!);
      if (amount != null && amount > 0) {
        return ParsedTransaction(
          type: 'deposit',
          amount: amount,
          description: _cleanDescription(content, 'Orange Money'),
          source: 'orange_money',
          rawTitle: title,
          rawContent: content,
          date: DateTime.now(),
        );
      }
    }

    // Sent / Transfer: "Envoi de 5 000 FCFA" or "Transfert de 5 000 FCFA"
    final envoyeMatch = RegExp(
      r'(?:envoy[eé]|envoi|sent|transfert(?!\s+re[cç]u)|transfer)\s+(?:de\s+)?([\d\s.,]+)\s*(?:f(?:\s*cfa)?|xof)',
      caseSensitive: false,
    ).firstMatch(text);
    if (envoyeMatch != null) {
      final amount = _parseAmount(envoyeMatch.group(1)!);
      if (amount != null && amount > 0) {
        return ParsedTransaction(
          type: 'withdrawal',
          amount: amount,
          description: _cleanDescription(content, 'Orange Money'),
          source: 'orange_money',
          rawTitle: title,
          rawContent: content,
          date: DateTime.now(),
        );
      }
    }

    // Payment: "Paiement de 5 000 FCFA"
    final paiementMatch = RegExp(
      r'(?:paiement|payment|pay[eé]|achat)\s+(?:de\s+)?([\d\s.,]+)\s*(?:f(?:\s*cfa)?|xof)',
      caseSensitive: false,
    ).firstMatch(text);
    if (paiementMatch != null) {
      final amount = _parseAmount(paiementMatch.group(1)!);
      if (amount != null && amount > 0) {
        return ParsedTransaction(
          type: 'withdrawal',
          amount: amount,
          description: _cleanDescription(content, 'Orange Money'),
          source: 'orange_money',
          rawTitle: title,
          rawContent: content,
          date: DateTime.now(),
        );
      }
    }

    // Withdrawal: "Retrait de 5 000 FCFA"
    final retraitMatch = RegExp(
      r'(?:retrait|withdrawal|retire)\s+(?:de\s+)?([\d\s.,]+)\s*(?:f(?:\s*cfa)?|xof)',
      caseSensitive: false,
    ).firstMatch(text);
    if (retraitMatch != null) {
      final amount = _parseAmount(retraitMatch.group(1)!);
      if (amount != null && amount > 0) {
        return ParsedTransaction(
          type: 'withdrawal',
          amount: amount,
          description: _cleanDescription(content, 'Orange Money'),
          source: 'orange_money',
          rawTitle: title,
          rawContent: content,
          date: DateTime.now(),
        );
      }
    }

    // Fallback
    return _tryGenericParse(title, content, 'orange_money');
  }

  /// Parse Orange Money SMS. Returns null if not a recognised transaction.
  /// All confirmed OM SMS end with "Merci.OFMS".
  static ParsedTransaction? parseSms(String body) {
    if (!body.contains('OFMS')) return null;

    final text = body.toLowerCase();

    // "Votre transfert de 1200.00Fcfa vers ..." → withdrawal
    final sentMatch = RegExp(
      r'votre transfert de\s*([\d.,]+)\s*(?:f(?:\s*cfa)?|xof)\s+vers',
      caseSensitive: false,
    ).firstMatch(text);
    if (sentMatch != null) {
      final amount = _parseAmount(sentMatch.group(1)!);
      if (amount != null && amount > 0) {
        return ParsedTransaction(
          type: 'withdrawal',
          amount: amount,
          description: _cleanDescription(body, 'Orange Money'),
          source: 'orange_money',
          rawTitle: 'Orange Money',
          rawContent: body,
          date: DateTime.now(),
        );
      }
    }

    // "Vous avez recu un transfert de 10000.00FCFA de ..." → deposit
    final receivedMatch = RegExp(
      r'vous avez re[cç]u\s+un\s+transfert\s+de\s*([\d.,]+)\s*(?:f(?:\s*cfa)?|xof)',
      caseSensitive: false,
    ).firstMatch(text);
    if (receivedMatch != null) {
      final amount = _parseAmount(receivedMatch.group(1)!);
      if (amount != null && amount > 0) {
        return ParsedTransaction(
          type: 'deposit',
          amount: amount,
          description: _cleanDescription(body, 'Orange Money'),
          source: 'orange_money',
          rawTitle: 'Orange Money',
          rawContent: body,
          date: DateTime.now(),
        );
      }
    }

    // "Vous avez retire 7000.00FCFA par le distributeur ..." → withdrawal
    final withdrawalMatch = RegExp(
      r'vous avez retir[eé]\s*([\d.,]+)\s*(?:f(?:\s*cfa)?|xof)',
      caseSensitive: false,
    ).firstMatch(text);
    if (withdrawalMatch != null) {
      final amount = _parseAmount(withdrawalMatch.group(1)!);
      if (amount != null && amount > 0) {
        return ParsedTransaction(
          type: 'withdrawal',
          amount: amount,
          description: _cleanDescription(body, 'Orange Money'),
          source: 'orange_money',
          rawTitle: 'Orange Money',
          rawContent: body,
          date: DateTime.now(),
        );
      }
    }

    // Generic fallback: first FCFA/F amount in OFMS-marked SMS
    return _tryGenericParse('Orange Money', body, 'orange_money');
  }

  static ParsedTransaction? _tryGenericParse(
      String title, String content, String source) {
    final text = '$title $content';

    // Look for any amount followed by FCFA
    final match = RegExp(
      r'([\d\s.,]+)\s*(?:f(?:\s*cfa)?|xof)',
      caseSensitive: false,
    ).firstMatch(text);

    if (match != null) {
      final amount = _parseAmount(match.group(1)!);
      if (amount != null && amount > 0) {
        // Try to determine type from context
        final lowerText = text.toLowerCase();
        final isDeposit = lowerText.contains('recu') ||
            lowerText.contains('reçu') ||
            lowerText.contains('depot') ||
            lowerText.contains('dépôt') ||
            lowerText.contains('crédit') ||
            lowerText.contains('received') ||
            lowerText.contains('deposit');

        return ParsedTransaction(
          type: isDeposit ? 'deposit' : 'withdrawal',
          amount: amount,
          description: _cleanDescription(
              content, source == 'wave' ? 'Wave' : 'Orange Money'),
          source: source,
          rawTitle: title,
          rawContent: content,
          date: DateTime.now(),
        );
      }
    }

    return null;
  }

  static double? _parseAmount(String raw) {
    String cleaned = raw.trim();
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), '');

    final commaCount = ','.allMatches(cleaned).length;
    final dotCount = '.'.allMatches(cleaned).length;

    if (cleaned.contains('.') && cleaned.contains(',')) {
      // Mixte : le dernier séparateur est le décimal
      if (cleaned.lastIndexOf(',') > cleaned.lastIndexOf('.')) {
        // "5.000,50" → européen
        cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
      } else {
        // "5,000.50" → américain
        cleaned = cleaned.replaceAll(',', '');
      }
    } else if (commaCount > 1) {
      // "1,000,000" → séparateurs de milliers multiples
      cleaned = cleaned.replaceAll(',', '');
    } else if (dotCount > 1) {
      // "1.000.000" → séparateurs de milliers multiples
      cleaned = cleaned.replaceAll('.', '');
    } else if (cleaned.contains(',')) {
      final parts = cleaned.split(',');
      // Si partie décimale ≤ 2 chiffres → virgule décimale ("5,50")
      // Sinon → séparateur de milliers ("5,000")
      if (parts.length == 2 && parts[1].length <= 2) {
        cleaned = cleaned.replaceAll(',', '.');
      } else {
        cleaned = cleaned.replaceAll(',', '');
      }
    } else if (cleaned.contains('.')) {
      final parts = cleaned.split('.');
      // Si partie décimale ≤ 2 chiffres → point décimal ("5.50")
      // Sinon → séparateur de milliers ("5.000")
      if (parts.length == 2 && parts[1].length > 2) {
        cleaned = cleaned.replaceAll('.', '');
      }
    }

    return double.tryParse(cleaned);
  }

  static String _cleanDescription(String content, String sourceName) {
    // Truncate long notification text, keep first meaningful part
    String desc = content.trim();
    if (desc.length > 100) {
      desc = '${desc.substring(0, 97)}...';
    }
    if (desc.isEmpty) {
      desc = 'Transaction $sourceName';
    }
    return desc;
  }
}
