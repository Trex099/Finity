import SwiftUI

struct TodoItem: View {
    var todo: Todo
    var onToggleComplete: (Todo) -> Void
    var onDelete: (Todo) -> Void
    
    var body: some View {
        HStack {
            Button(action: {
                onToggleComplete(todo)
            }) {
                Image(systemName: todo.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(todo.completed ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text(todo.title)
                .strikethrough(todo.completed, color: .gray)
                .foregroundColor(todo.completed ? .gray : .primary)
                .padding(.leading, 8)
            
            Spacer()
            
            Button(action: {
                onDelete(todo)
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .font(.system(size: 16))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
} 