const String kInitialSettingJson = "assets/setting/initial_settings.json";

// Minimum transaction amounts
const double MINIMUM_DEPOSIT_AMOUNT = 500.0;
const double MINIMUM_WITHDRAW_AMOUNT = 500.0;
const double MINIMUM_BALANCE_FOR_TASKS = 500.0;

// Transaction validation messages
const String MIN_DEPOSIT_MESSAGE = "Minimum deposit amount is 500 PKR";
const String MIN_WITHDRAW_MESSAGE = "Minimum withdraw amount is 500 PKR";
const String INSUFFICIENT_BALANCE_MESSAGE =
    "Insufficient balance. You have {amount} PKR available";
const String LOW_BALANCE_TASK_MESSAGE =
    "Your balance is too low. Please deposit at least 500 to access tasks.";
