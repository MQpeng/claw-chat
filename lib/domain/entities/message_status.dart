enum MessageStatus {
  sending,
  sent,
  error;

  bool get isSending => this == MessageStatus.sending;
  bool get isSent => this == MessageStatus.sent;
  bool get isError => this == MessageStatus.error;
}
