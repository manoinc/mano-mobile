// The D6 (billing) GraphQL documents the wallet and payout adapters send.

const coinWalletQuery = 'query CoinWallet { myCoinWallet { balance } }';

const coinPacksQuery =
    'query CoinPacks { coinPacks { id coins bonus price { amount currency } } }';

const coinMovementsQuery = '''
query CoinMovements {
  myCoinMovements(page: {first: 50}) {
    items { id type coins paymentId leadId createdAt }
  }
}''';

const buyCoinPackMutation = r'''
mutation BuyCoinPack($packId: ID!, $method: PaymentMethodInput!, $payerEmail: String!, $termsAccepted: Boolean!) {
  buyCoinPack(packId: $packId, method: $method, payerEmail: $payerEmail, termsAccepted: $termsAccepted) {
    payment { id status coins failureReason }
    nextAction { type redirectUrl }
  }
}''';

const _jobPaymentResult = '''
    payment { id purpose jobId amount { amount currency } feeAmount { amount currency } netToWorker { amount currency } method status failureReason }
    nextAction { type redirectUrl }''';

const payJobMutation =
    '''
mutation PayJob(\$jobId: ID!, \$method: PaymentMethodInput!, \$payerEmail: String!, \$termsAccepted: Boolean!) {
  payJob(jobId: \$jobId, method: \$method, payerEmail: \$payerEmail, termsAccepted: \$termsAccepted) {$_jobPaymentResult
  }
}''';

const jobPaymentQuery =
    '''
query JobPayment(\$jobId: ID!) {
  jobPayment(jobId: \$jobId) {$_jobPaymentResult
  }
}''';

const checkoutTermsQuery =
    'query CheckoutTerms { checkoutTerms { label url } }';

const pseBanksQuery = 'query PseBanks { pseBanks { code name } }';

const leadPricesQuery =
    'query LeadPrices { leadPrices { defaultCoins prices { category coins } } }';

const payoutBanksQuery = 'query PayoutBanks { payoutBanks { code name } }';

const registerPayoutAccountMutation = r'''
mutation RegisterPayoutAccount($input: PayoutAccountInput!) {
  registerPayoutAccount(input: $input) { id type bankCode last4 createdAt }
}''';
