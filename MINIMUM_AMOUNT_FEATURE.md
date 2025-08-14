# Minimum Amount Feature Implementation

## Overview

This feature implements a minimum transaction amount of **500 PKR** for both deposit and withdraw operations in the Leasure NFT app. Users cannot deposit or withdraw amounts less than 500 PKR.

## Features Implemented

### 1. **Minimum Amount Validation**
- **Deposit**: Minimum 500 PKR required
- **Withdraw**: Minimum 500 PKR required
- **Task Access**: Minimum 500 PKR balance required

### 2. **Validation Layers**
- **Frontend Validation**: Form validation with error messages
- **Backend Validation**: Controller-level validation before processing
- **UI Feedback**: Real-time balance information and status indicators

### 3. **User Experience Enhancements**
- **Info Cards**: Display minimum amount requirements
- **Balance Cards**: Show current balance and withdrawal eligibility
- **Error Messages**: Clear feedback when minimum requirements aren't met

## Implementation Details

### Constants Configuration
```dart
// lib/app/core/assets/constant.dart
const double MINIMUM_DEPOSIT_AMOUNT = 500.0;
const double MINIMUM_WITHDRAW_AMOUNT = 500.0;
const double MINIMUM_BALANCE_FOR_TASKS = 500.0;

const String MIN_DEPOSIT_MESSAGE = "Minimum deposit amount is 500 PKR";
const String MIN_WITHDRAW_MESSAGE = "Minimum withdraw amount is 500 PKR";
const String INSUFFICIENT_BALANCE_MESSAGE = "Insufficient balance. You have {amount} PKR available";
const String LOW_BALANCE_TASK_MESSAGE = "Your balance is too low. Please deposit at least 500 to access tasks.";
```

### Deposit Validation
```dart
// lib/app/users/screens/dashboard/deposit/controller/deposit_controller.dart
final depositAmount = double.tryParse(amountController.text.trim()) ?? 0.0;
if (depositAmount < MINIMUM_DEPOSIT_AMOUNT) {
  Fluttertoast.showToast(
    msg: MIN_DEPOSIT_MESSAGE,
    backgroundColor: Colors.red,
  );
  isloading.value = false;
  return;
}
```

### Withdraw Validation
```dart
// lib/app/users/screens/dashboard/withdraw/controller/user_withdraw_controller.dart
final withdrawAmount = double.tryParse(amountController.text.trim()) ?? 0.0;
if (withdrawAmount < MINIMUM_WITHDRAW_AMOUNT) {
  showToast(MIN_WITHDRAW_MESSAGE, isError: true);
  return;
}

// Check if user has enough balance
if (cashVault.value < withdrawAmount) {
  showToast(
    INSUFFICIENT_BALANCE_MESSAGE.replaceAll('{amount}', cashVault.value.toString()),
    isError: true
  );
  isloading.value = false;
  return;
}
```

### Task Access Validation
```dart
// lib/app/users/screens/dashboard/task/controller/user_task_controller.dart
if (cashVault < MINIMUM_BALANCE_FOR_TASKS) {
  errorMsg.value = LOW_BALANCE_TASK_MESSAGE;
  throw Exception(LOW_BALANCE_TASK_MESSAGE);
}
```

## UI Components

### 1. MinimumAmountInfo Widget
```dart
MinimumAmountInfo(
  transactionType: 'deposit', // or 'withdraw'
  backgroundColor: AppColors.primaryColor.withOpacity(0.1),
)
```

**Features:**
- Shows minimum amount requirement
- Different styling for deposit/withdraw
- Info icon with clear messaging

### 2. BalanceInfoCard Widget
```dart
BalanceInfoCard(
  currentBalance: controller.cashVault.value,
  transactionType: 'withdraw',
)
```

**Features:**
- Displays current balance
- Shows withdrawal eligibility
- Color-coded status (green/red)
- Real-time balance updates

## Form Validation

### Deposit Form
```dart
validator: (value) {
  if (value!.isEmpty) {
    return 'Amount is required';
  }
  final amount = double.tryParse(value) ?? 0.0;
  if (amount < MINIMUM_DEPOSIT_AMOUNT) {
    return MIN_DEPOSIT_MESSAGE;
  }
  return null;
},
```

### Withdraw Form
```dart
validator: (value) {
  if (value!.isEmpty) {
    return 'Please enter amount';
  }
  final amount = double.tryParse(value) ?? 0.0;
  if (amount < MINIMUM_WITHDRAW_AMOUNT) {
    return MIN_WITHDRAW_MESSAGE;
  }
  return null;
},
```

## Error Handling

### 1. **Insufficient Balance**
- Shows current available balance
- Prevents transaction processing
- Clear error message

### 2. **Below Minimum Amount**
- Form validation prevents submission
- Toast message with minimum requirement
- Visual feedback in UI

### 3. **Task Access Denied**
- Blocks access to task screen
- Shows deposit requirement message
- Redirects to deposit screen

## User Flow

### Deposit Flow
1. User navigates to deposit screen
2. Sees minimum amount info card
3. Enters amount (validated for minimum 500)
4. Form validation prevents submission if below minimum
5. Controller validates amount before processing
6. Transaction proceeds if validation passes

### Withdraw Flow
1. User navigates to withdraw screen
2. Sees current balance and eligibility
3. Sees minimum amount requirement
4. Enters amount (validated for minimum 500)
5. System checks if user has sufficient balance
6. Transaction proceeds if all validations pass

### Task Access Flow
1. User tries to access task screen
2. System checks current balance
3. If below 500 PKR, shows error message
4. User must deposit to access tasks

## Benefits

### 1. **Business Logic**
- Prevents micro-transactions
- Ensures meaningful transaction amounts
- Reduces processing overhead

### 2. **User Experience**
- Clear expectations about minimum amounts
- Real-time balance information
- Helpful error messages

### 3. **System Integrity**
- Consistent validation across all layers
- Prevents invalid transactions
- Maintains data consistency

## Configuration

### Changing Minimum Amounts
To change the minimum amounts, update the constants in `lib/app/core/assets/constant.dart`:

```dart
const double MINIMUM_DEPOSIT_AMOUNT = 1000.0; // Change to 1000 PKR
const double MINIMUM_WITHDRAW_AMOUNT = 1000.0; // Change to 1000 PKR
const double MINIMUM_BALANCE_FOR_TASKS = 1000.0; // Change to 1000 PKR
```

### Customizing Messages
Update the message constants for different languages or custom messages:

```dart
const String MIN_DEPOSIT_MESSAGE = "Minimum deposit amount is 1000 PKR";
const String MIN_WITHDRAW_MESSAGE = "Minimum withdraw amount is 1000 PKR";
```

## Testing Scenarios

### 1. **Valid Transactions**
- Deposit 500 PKR ✓
- Deposit 1000 PKR ✓
- Withdraw 500 PKR (if balance >= 500) ✓
- Withdraw 1000 PKR (if balance >= 1000) ✓

### 2. **Invalid Transactions**
- Deposit 499 PKR ✗
- Deposit 0 PKR ✗
- Withdraw 499 PKR ✗
- Withdraw 1000 PKR (balance 500) ✗

### 3. **Edge Cases**
- Empty amount field ✗
- Non-numeric input ✗
- Negative amounts ✗
- Zero amounts ✗

## Future Enhancements

### 1. **Dynamic Minimum Amounts**
- Admin-configurable minimum amounts
- Different minimums for different user tiers
- Time-based minimum amount changes

### 2. **Enhanced Validation**
- Maximum amount limits
- Daily transaction limits
- Weekly/monthly limits

### 3. **Better UX**
- Amount suggestions
- Quick amount buttons (500, 1000, 2000)
- Balance prediction after transaction

---

**Note**: This implementation ensures that users cannot perform transactions below the minimum amount while providing clear feedback and maintaining a good user experience. 