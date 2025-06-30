import SwiftUI

struct MessageBubble: View {
    let message: Message
    let isFromCurrentUser: Bool
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer()
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 2) {
                if !isFromCurrentUser {
                    Text(message.senderName)
                        .font(.caption)
                        .foregroundColor(ThemeColors.secondaryText)
                        .padding(.leading, 8)
                }
                
                Text(message.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        isFromCurrentUser ? 
                            ThemeColors.primary :
                            ThemeColors.secondaryBackground
                    )
                    .foregroundColor(isFromCurrentUser ? ThemeColors.primaryText : ThemeColors.primaryText)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 2)
                
                Text(formatTimestamp(message.timestamp))
                    .font(.caption2)
                    .foregroundColor(ThemeColors.tertiaryText)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 2)
            }
            
            if !isFromCurrentUser {
                Spacer()
            }
        }
    }
    
    private func formatTimestamp(_ timestamp: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        if Calendar.current.isDateInToday(timestamp) {
            return formatter.string(from: timestamp)
        } else {
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            return formatter.string(from: timestamp)
        }
    }
} 