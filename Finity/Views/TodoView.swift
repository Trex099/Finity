import SwiftUI

struct TodoView: View {
    @StateObject private var todoService = TodoService()
    @State private var newTodoTitle = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Input field for new todos
                HStack {
                    TextField("Add a new todo", text: $newTodoTitle)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    Button(action: addTodo) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.blue)
                    }
                    .disabled(newTodoTitle.isEmpty)
                }
                .padding([.horizontal, .top])
                
                // Todo list
                List {
                    ForEach(todoService.todos) { todo in
                        TodoItem(
                            todo: todo,
                            onToggleComplete: { todoService.toggleTodoComplete(todo: $0) },
                            onDelete: { todoService.deleteTodo(todo: $0) }
                        )
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Todo List")
        }
    }
    
    private func addTodo() {
        guard !newTodoTitle.isEmpty else { return }
        
        todoService.addTodo(title: newTodoTitle)
        newTodoTitle = ""
    }
} 