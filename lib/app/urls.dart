class Urls {
  // =========================================== Base ================================================ //
  // static const String _baseUrl = 'http://10.10.10.17:5005/api/v1';
  // static const String socketUrl = 'http://10.10.10.17:4000/';

  // static const String _baseUrl = 'http://10.10.10.17:5000/api/v1';
  // static const String _baseUrl = 'https://wisper.up.railway.app/api/v1';
//  static const String _baseUrl = 'https://cd234531fe15.ngrok-free.app/api/v1';
 // static const String socketUrl = 'https://cd234531fe15.ngrok-free.app';
  static const String _baseUrl = 'https://api.wisperonline.com/api/v1';
  static const String baseUrl = 'https://api.wisperonline.com/api/v1'; // Added for Monnify controller
  static const String socketUrl = 'https://api.wisperonline.com';

  
  
  // =========================================== Common ============================================== //
  static const String paymentUrl = '$_baseUrl/boosts/checkout-session';
  static const String contentUrl = '$_baseUrl/legal'; 
  
  // =========================================== Profile ============================================== //
  static const String personProfileUrl = '$_baseUrl/persons/profile';
  static const String businessProfileUrl = '$_baseUrl/businesses/profile';
  static const String personEditProfileUrl = '$_baseUrl/persons/profile';
  static const String businessEditProfileUrl = '$_baseUrl/businesses/profile';
  static const String personEditProfilePhotoUrl =
      '$_baseUrl/persons/profile-image'; 
  static const String businessEditProfilePhotoUrl = 
      '$_baseUrl/businesses/profile-image';
  
  // =========================================== Authentication ====================================== //
  static const String signUpUrlPerson = '$_baseUrl/auths/person/signup';
  static const String signUpUrlBussiness = '$_baseUrl/auths/business/signup';
  static const String refreshTokenUrl = '$_baseUrl/auth/refresh-token';
  static const String googleAuthUrl = '$_baseUrl/auths/google-login';
  static const String otpVerifyUrl = '$_baseUrl/otps/verify';
  static const String resendOtpUrl = '$_baseUrl/otps/send';
  static const String signInUrl = '$_baseUrl/auths/login';
  static const String forgotPasswordUrl = '$_baseUrl/otps/send';
  static const String changePasswordUrl = '$_baseUrl/auths/change-password';
  static const String deleteAccountUrl = '$_baseUrl/auth/change-password';
  static const String resterPasswordUrl = '$_baseUrl/auths/reset-password';

  // =========================================== Profile Block ======================================= //
  static const String updateProfileUrl = '$_baseUrl/teachers/profile';
  static const String updateProfilImageUrl =
      '$_baseUrl/teachers/profile/change-image';
  static const String allConnectionUrl = '$_baseUrl/connections';
  static const String recommendationsUrl = '$_baseUrl/recommendations';
  static const String addRequestUrl = '$_baseUrl/connections';
  static const String boostPackaegesUrl = '$_baseUrl/boost-packages';
  static const String favoritesUrl = '$_baseUrl/favorites';

   static String otherProfileById(String id) {
    return '$_baseUrl/persons/$id';
  }

  static String joinGroupById(String id) {
    return '$_baseUrl/groups/join/$id';
  }
 
 
  static String chatDataById(String id) {
    return '$_baseUrl/chats/files/$id';
  }

  static String updateConnectionById(String id) {
    return '$_baseUrl/connections/$id';
  }

  static String favoriteJobById(String id) {
    return '$_baseUrl/favorites/$id';
  }

  static String otherBusinessProfileById(String id) {
    return '$_baseUrl/businesses/$id';
  }

  static String recommendationById(String id) {
    return '$_baseUrl/recommendations/$id';
  }

  // =========================================== Home Block ========================================== //
  static const String feedPostUrl = '$_baseUrl/posts/feed';
  static const String myFeedPostUrl = '$_baseUrl/posts/all';
  static const String postUrl = '$_baseUrl/posts';
  static const String resumePostUrl = '$_baseUrl/resumes';
  static const String feedJobUrl = '$_baseUrl/jobs';
  static const String roleUrl = '$_baseUrl/persons/roles';
  static const String walletUrl = '$_baseUrl/payments';
  static const String allGroupUrl = '$_baseUrl/groups';

  // =========================================== KYC Block =========================================== //
  static const String kycStatusUrl = '$_baseUrl/kyc/status';
  static const String kycSubmitUrl = '$_baseUrl/kyc/submit'; // legacy compat
  static const String kycEmailSendOtpUrl = '$_baseUrl/kyc/email/send-otp';
  static const String kycEmailVerifyUrl = '$_baseUrl/kyc/email/verify';
  static const String kycPhoneSendOtpUrl = '$_baseUrl/kyc/phone/send-otp';
  static const String kycPhoneVerifyUrl = '$_baseUrl/kyc/phone/verify';
  static const String kycNinVerifyUrl = '$_baseUrl/kyc/nin/verify';
  static const String kycAddressSubmitUrl = '$_baseUrl/kyc/address/submit';
  static const String kycBadgeActivateUrl = '$_baseUrl/kyc/badge/activate';
  static const String kycBadgePayOutstandingUrl = '$_baseUrl/kyc/badge/pay-outstanding';

  // =========================================== Monnify Wallet ================================== //
  static const String monnifyInitializeUrl = '$_baseUrl/wallet/monnify/initialize';
  static const String monnifyVerifyUrl = '$_baseUrl/wallet/monnify/verify';
  static const String walletBalanceUrl = '$_baseUrl/wallet/balance';
  static const String monnifyWithdrawUrl = '$_baseUrl/wallet/withdraw';
  static const String monnifyAuthorizeWithdrawalUrl = '$_baseUrl/wallet/authorize-withdrawal';

  // Gig Market search
  static String gigMarketSearchUrl(String q, {String? country}) {
    final base = '$_baseUrl/posts/search/gig-market?q=${Uri.encodeComponent(q)}&limit=20';
    if (country != null && country.isNotEmpty) {
      return '$base&country=${Uri.encodeComponent(country)}';
    }
    return base;
  }
 
  static String editPostId(String id) {
    return '$_baseUrl/posts/$id';
  }

  static String postViewUrl(String id) {
    return '$_baseUrl/posts/view/$id';
  }

  // Job title autocomplete
  static String jobTitleSearchUrl(String q) {
    return '$_baseUrl/job-titles/search?q=${Uri.encodeComponent(q)}&limit=20';
  }

  static String resumeById(String id) {
    return '$_baseUrl/resumes/$id';
  }

  static String commentPostId(String id) {
    return '$_baseUrl/comments/$id';
  }

  static String otherUserPostById(String id) {
    return '$_baseUrl/posts/user/$id'; 
  }

  static String otherUserJobById(String id) {
    return '$_baseUrl/jobs/user/$id';
  }

  static String singleJobById(String id) {
    return '$_baseUrl/jobs/$id';
  }

  static String deleteNotificationById(String id) {
    return '$_baseUrl/notifications/$id';
  }

  // =========================================== Chat Block =========================================== //
  static const String createGroupUrl = '$_baseUrl/groups';
  static const String createClassUrl = '$_baseUrl/classes';
  static const String allChatsUrl = '$_baseUrl/chats/my';
  static const String createChatsUrl = '$_baseUrl/chats';
  static const String blockChatUserUrl = '$_baseUrl/chats/block-participant'; 
  static const String unblockChatUserUrl =
      '$_baseUrl/chats/unblock-participant';
  static const String muteChatUserUrl = '$_baseUrl/chats/mute';
  static const String fileDecodeUrl = '$_baseUrl/upload-files/';
  static const String chatDataUrl = '$_baseUrl/chats/files';

  static String groupInfoById(String id) {
    return '$_baseUrl/groups/$id';
  }

    static String seenMessageById(String id) {
    return '$_baseUrl/messages/seen/$id';
  }

  static String changeGroupImageById(String id) {
    return '$_baseUrl/groups/image/$id';
  }

  static String changeClassImageById(String id) {
    return '$_baseUrl/classes/image/$id';
  }

  static String classInfoById(String id) {
    return '$_baseUrl/classes/$id';
  }

  static String groupMuteInfoById(String id) {
    return '$_baseUrl/chats/mute-info/$id';
  }

  static String groupMembersById(String id) {
    return '$_baseUrl/groups/members/$id';
  }

  static String classMembersById(String id) {
    return '$_baseUrl/classes/members/$id';
  }

  static String addMembersById(String id) {
    return '$_baseUrl/groups/$id';
  }

  static String deleteGroupById(String id) {
    return '$_baseUrl/chats/$id';
  }

  static String messagesById(String id) {
    return '$_baseUrl/messages/$id';
  } 
}
