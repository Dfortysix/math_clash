// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Math Clash';

  @override
  String get soloMode => 'Chế độ Solo';

  @override
  String get createPvpRoom => 'Tạo phòng PvP';

  @override
  String get joinPvpRoom => 'Tham gia phòng PvP';

  @override
  String get quickMatch => 'Ghép trực tuyến';

  @override
  String get leaderboard => 'Bảng Xếp Hạng';

  @override
  String get signInGoogle => 'Đăng nhập Google';

  @override
  String get signOutGoogle => 'Đăng xuất Google';

  @override
  String get turnOffMusic => 'Tắt nhạc nền';

  @override
  String get turnOnMusic => 'Mở nhạc nền';

  @override
  String get soloModeDescription => 'Trả lời 15 câu hỏi toán học\nCàng nhanh càng được nhiều điểm!';

  @override
  String get signInToSaveScore => 'Đăng nhập Google để lưu điểm vào bảng xếp hạng';

  @override
  String get start => 'Bắt đầu';

  @override
  String get question => 'Câu hỏi';

  @override
  String get score => 'Điểm';

  @override
  String timeRemaining(Object seconds) {
    return 'Thời gian: ${seconds}s';
  }

  @override
  String get gameCompleted => 'Bạn đã hoàn thành!';

  @override
  String yourScore(Object score) {
    return 'Số điểm: $score';
  }

  @override
  String get signInToSave => 'Đăng nhập để lưu điểm';

  @override
  String get scoreNotSaved => 'Điểm số sẽ không được lưu vào bảng xếp hạng';

  @override
  String get close => 'Đóng';

  @override
  String get playAgain => 'Chơi lại';

  @override
  String get backToMenu => 'Về menu';

  @override
  String get roomCode => 'Mã phòng';

  @override
  String get copyRoomCode => 'Sao chép mã phòng';

  @override
  String get roomCodeCopied => 'Đã sao chép mã phòng!';

  @override
  String get startGame => 'Bắt đầu game';

  @override
  String get waitingForPlayers => 'Đang chờ người chơi khác...';

  @override
  String get enterRoomCode => 'Nhập mã phòng để tham gia';

  @override
  String get pleaseEnterRoomCode => 'Vui lòng nhập mã phòng';

  @override
  String get needGoogleSignIn => 'Bạn cần đăng nhập Google';

  @override
  String get cannotJoinRoom => 'Không thể tham gia phòng';

  @override
  String get leaveRoom => 'Rời phòng';

  @override
  String get featureInDevelopment => 'Chức năng đang phát triển!';

  @override
  String get error => 'Lỗi';

  @override
  String get tryAgain => 'Thử lại';

  @override
  String get noLeaderboardData => 'Chưa có dữ liệu xếp hạng';

  @override
  String get notSignedIn => 'Chưa đăng nhập';

  @override
  String get signInToSaveLeaderboard => 'Đăng nhập Google để lưu điểm vào bảng xếp hạng';

  @override
  String get pvpMode => 'Chế độ PvP';

  @override
  String get soundError => 'Lỗi phát âm thanh';

  @override
  String get settings => 'Cài đặt';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get about => 'Giới thiệu';

  @override
  String get appDescription => 'Math Clash - Trò chơi toán học vui nhộn!';

  @override
  String get languageChanged => 'Đã đổi ngôn ngữ!';

  @override
  String get join => 'Tham gia';

  @override
  String get savingScore => 'Đang lưu điểm...';

  @override
  String get you => 'Bạn';

  @override
  String get waiting => 'Chờ người chơi';

  @override
  String get playing => 'Đang chơi';

  @override
  String get finished => 'Đã kết thúc';

  @override
  String get unknown => 'Không xác định';

  @override
  String get leaveRoomConfirm => 'Bạn có chắc muốn rời phòng?';

  @override
  String get cancel => 'Hủy';

  @override
  String get leavingRoom => 'Đang rời phòng...';

  @override
  String get leaveRoomError => 'Có lỗi xảy ra khi rời phòng';

  @override
  String get creatingRoom => 'Đang tạo phòng...';

  @override
  String get pleaseSignInGoogle => 'Vui lòng đăng nhập bằng Google để lưu điểm';

  @override
  String get errorSavingScore => 'Lỗi khi lưu điểm';

  @override
  String get roomNotExists => 'Phòng không tồn tại!';

  @override
  String get roomFull => 'Phòng đã đủ người!';

  @override
  String get googleSignInTimeout => 'Đăng nhập Google quá lâu, vui lòng thử lại!';

  @override
  String get errorGoogleSignIn => 'Lỗi khi đăng nhập Google';

  @override
  String get errorGoogleSignOut => 'Lỗi khi đăng xuất';

  @override
  String get players => 'Người chơi';

  @override
  String get playersInRoom => 'Người chơi trong phòng';

  @override
  String get signedIn => 'Đã đăng nhập';

  @override
  String get roomHost => 'Chủ phòng';

  @override
  String get sounds => 'Âm thanh';

  @override
  String get settings_developer => 'Người phát triển:';

  @override
  String get settings_developer_name => 'Nguyễn Trí Dũng';

  @override
  String get ready => 'Sẵn sàng';

  @override
  String get notReady => 'Chưa sẵn sàng';

  @override
  String get cancelReady => 'Hủy sẵn sàng';

  @override
  String get kick => 'Kick';
}
