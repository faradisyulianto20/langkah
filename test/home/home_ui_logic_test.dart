import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langkah/core/constants/app_colors.dart';
import 'package:langkah/core/widgets/user_avatar.dart';
import 'package:langkah/features/home/domain/home_messages.dart';
import 'package:langkah/features/settings/domain/avatar_image.dart';

void main() {
  group('HomeMessages (teks dinamis)', () {
    test('headline mengikuti jumlah selesai dari total', () {
      expect(HomeMessages.headline(0, 0), contains('satu langkah kecil'));
      expect(HomeMessages.headline(0, 1), contains('Satu langkah menunggumu'));
      expect(HomeMessages.headline(0, 5), contains('5 langkah menunggumu'));
      expect(HomeMessages.headline(1, 5), contains('1 langkah selesai'));
      expect(HomeMessages.headline(3, 5), contains('tinggal 2 lagi'));
      expect(HomeMessages.headline(4, 5), contains('Tinggal satu langkah'));
      expect(HomeMessages.headline(5, 5), contains('Semua 5 langkah tuntas'));
      expect(HomeMessages.headline(1, 1), contains('tuntas'));
    });

    test('dua baris teks progres tanpa format ../..', () {
      expect(HomeMessages.completedLabel(2, 5), '2 langkah selesai');
      expect(HomeMessages.remainingLabel(2, 5), 'sisa 3 langkah lagi');
      expect(HomeMessages.completedLabel(0, 0), 'Belum ada langkah');
      expect(HomeMessages.remainingLabel(0, 0), 'Tambahkan langkah pertamamu');
      expect(
        HomeMessages.remainingLabel(5, 5),
        'Semua langkah hari ini tuntas',
      );
      for (final (d, t) in [(0, 3), (2, 5), (5, 5)]) {
        expect(HomeMessages.completedLabel(d, t), isNot(contains('/')));
        expect(HomeMessages.remainingLabel(d, t), isNot(contains('/')));
      }
    });

    test('tidak ada emoji pada teks', () {
      final emoji = RegExp(
        r'[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]',
        unicode: true,
      );
      for (var t = 0; t <= 6; t++) {
        for (var d = 0; d <= t; d++) {
          expect(emoji.hasMatch(HomeMessages.headline(d, t)), isFalse);
          expect(emoji.hasMatch(HomeMessages.completedLabel(d, t)), isFalse);
          expect(emoji.hasMatch(HomeMessages.remainingLabel(d, t)), isFalse);
        }
      }
    });
  });

  group('AppColors.progressColor', () {
    test('0% merah, 50% oranye, 100% hijau', () {
      expect(AppColors.progressColor(0), AppColors.error);
      expect(AppColors.progressColor(0.5), AppColors.warning);
      expect(AppColors.progressColor(1), AppColors.success);
    });

    test('di antaranya diinterpolasi & dibatasi 0..1', () {
      final quarter = AppColors.progressColor(0.25);
      expect(quarter, isNot(AppColors.error));
      expect(quarter, isNot(AppColors.warning));
      expect(AppColors.progressColor(-1), AppColors.error);
      expect(AppColors.progressColor(2), AppColors.success);
    });

    test('null = netral (belum ada data)', () {
      expect(AppColors.progressColor(null), AppColors.textSecondary);
    });
  });

  group('AvatarImage', () {
    test('mengenali tipe dari mime atau nama file', () {
      expect(AvatarImage.resolve(mimeType: 'image/png', fileName: 'x'), (
        contentType: 'image/png',
        extension: 'png',
      ));
      expect(AvatarImage.resolve(fileName: 'Foto.JPEG'), (
        contentType: 'image/jpeg',
        extension: 'jpg',
      ));
      expect(AvatarImage.resolve(fileName: 'a.webp'), (
        contentType: 'image/webp',
        extension: 'webp',
      ));
    });

    test('menolak format tak didukung', () {
      expect(AvatarImage.resolve(fileName: 'a.gif'), isNull);
      expect(AvatarImage.resolve(fileName: 'tanpa_ekstensi'), isNull);
      expect(
        AvatarImage.resolve(mimeType: 'application/pdf', fileName: 'a.pdf'),
        isNull,
      );
    });
  });

  group('UserAvatar', () {
    test('inisial dari nama', () {
      expect(UserAvatar.initialsOf('Faradis Yulianto'), 'FY');
      expect(UserAvatar.initialsOf('faradis'), 'F');
      expect(UserAvatar.initialsOf('  '), '');
    });

    testWidgets('menampilkan inisial bila tanpa foto', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: UserAvatar(name: 'Faradis Yulianto')),
        ),
      );
      expect(find.text('FY'), findsOneWidget);
    });
  });
}
