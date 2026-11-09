/// Mano's domain core.
///
/// Everything the app knows about *what Mano is* lives here: its entities, the
/// ports through which it reaches the outside world, and the failures those
/// ports may report. Nothing here knows how any of it is accomplished.
///
/// This package depends on nothing — not Flutter, not Riverpod, not a
/// functional-programming library. That is not incidental tidiness; it is the
/// mechanism that keeps the architecture honest. A framework import here fails
/// to resolve, so the boundary cannot erode through good intentions and a
/// deadline.
///
/// It also means this code runs anywhere Dart does: a test with no Flutter
/// binding, a command-line tool, a server, a future web client.
library;

export 'src/account/address_book.dart';
export 'src/account/card_validation.dart';
export 'src/account/client_profile.dart';
export 'src/account/client_profile_repository.dart';
export 'src/account/payment_method.dart';
export 'src/account/payment_methods.dart';
export 'src/account/saved_address.dart';
export 'src/catalog/catalog_repository.dart';
export 'src/catalog/job_service.dart';
export 'src/catalog/offer_management.dart';
export 'src/catalog/service_catalog.dart';
export 'src/catalog/service_categories.dart';
export 'src/catalog/service_category.dart';
export 'src/catalog/service_listing.dart';
export 'src/catalog/service_offer.dart';
export 'src/earnings/earnings.dart';
export 'src/earnings/earnings_repository.dart';
export 'src/jobs/job.dart';
export 'src/jobs/job_repository.dart';
export 'src/media/media_attachment.dart';
export 'src/media/media_picker.dart';
export 'src/media/media_uploader.dart';
export 'src/media/picked_image.dart';
export 'src/media/upload_target.dart';
export 'src/messaging/chat_repository.dart';
export 'src/messaging/conversation.dart';
export 'src/messaging/conversation_repository.dart';
export 'src/messaging/message.dart';
export 'src/onboarding/provider_onboarding.dart';
export 'src/payments/job_payment.dart';
export 'src/payments/job_payment_draft.dart';
export 'src/payments/job_payment_repository.dart';
export 'src/profile/provider_directory.dart';
export 'src/payouts/payout_account.dart';
export 'src/payouts/payout_account_draft.dart';
export 'src/payouts/payout_accounts.dart';
export 'src/profile/provider_profile.dart';
export 'src/profile/provider_profile_draft.dart';
export 'src/profile/provider_profile_editor.dart';
export 'src/profile/provider_profile_repository.dart';
export 'src/profile/public_provider_profile.dart';
export 'src/profile/referral_linker.dart';
export 'src/projects/already_quoted.dart';
export 'src/projects/contact_info.dart';
export 'src/projects/lead_repository.dart';
export 'src/projects/project.dart';
export 'src/projects/project_draft.dart';
export 'src/projects/project_repository.dart';
export 'src/projects/quote.dart';
export 'src/registration/registration_draft.dart';
export 'src/registration/registration_failure.dart';
export 'src/registration/registration_repository.dart';
export 'src/registration/registration_validation.dart';
export 'src/requests/service_request.dart';
export 'src/requests/service_request_repository.dart';
export 'src/result.dart';
export 'src/reviews/not_yet_reviewable.dart';
export 'src/reviews/rating_summary.dart';
export 'src/reviews/review.dart';
export 'src/reviews/review_draft.dart';
export 'src/reviews/review_page.dart';
export 'src/reviews/review_repository.dart';
export 'src/scheduling/availability.dart';
export 'src/scheduling/availability_repository.dart';
export 'src/session/auth_failure.dart';
export 'src/session/authenticated_user.dart';
export 'src/session/credentials.dart';
export 'src/session/credentials_validation.dart';
export 'src/session/otp_challenge.dart';
export 'src/session/passwordless_auth.dart';
export 'src/session/session.dart';
export 'src/session/session_repository.dart';
export 'src/session/social_auth.dart';
export 'src/shared/bank.dart';
export 'src/shared/colombian_mobile.dart';
export 'src/shared/data_failure.dart';
export 'src/shared/legal_id.dart';
export 'src/shared/mobile_phone.dart';
export 'src/shared/party.dart';
export 'src/support/support_desk.dart';
export 'src/support/support_ticket.dart';
export 'src/support/support_ticket_draft.dart';
export 'src/verification/identity_document_kind.dart';
export 'src/verification/identity_verification_port.dart';
export 'src/verification/identity_check_status.dart';
export 'src/wallet/checkout_term.dart';
export 'src/wallet/coin_pack.dart';
export 'src/wallet/coin_purchase.dart';
export 'src/wallet/coin_purchase_draft.dart';
export 'src/wallet/coin_transaction.dart';
export 'src/wallet/lead_pricing.dart';
export 'src/wallet/wallet.dart';
export 'src/wallet/wallet_repository.dart';
