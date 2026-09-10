import 'package:flutter_test/flutter_test.dart';
import 'package:misskey_gglp/mfm/nyaise.dart';

void main() {
  test('basic na -> nya', () {
    expect(nyaise('na'), 'nya');
  });

  test('case-preserving for the n', () {
    expect(nyaise('Na'), 'Nya');
    expect(nyaise('NA'), 'NYA');
    expect(nyaise('nA'), 'nyA');
  });

  test('multiple naa runs in sequence', () {
    expect(nyaise('banana'), 'banyanyana'.replaceAll('nyana', 'nya') == 'banyanyana'
        ? 'banyanyana'
        : 'banyanya');
    // Concretely:
    expect(nyaise('banana'), 'banyanya');
  });

  test('does not affect non-na sequences', () {
    expect(nyaise('hello world'), 'hello world');
    expect(nyaise('numero'), 'numero');
    expect(nyaise('nb'), 'nb');
  });

  test('mid-word', () {
    expect(nyaise('snack'), 'snyack');
    expect(nyaise('canada'), 'canyada');
  });

  test('empty input is empty', () {
    expect(nyaise(''), '');
  });

  test('trailing n is unchanged', () {
    expect(nyaise('moon'), 'moon');
    expect(nyaise('sun n'), 'sun n');
  });
}
