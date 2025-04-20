import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

class TodoService: ObservableObject {
    @Published var todos: [Todo] = []
    
    private let db = Firestore.firestore()
    private let collection = "todos"
    
    init() {
        fetchTodos()
    }
    
    func fetchTodos() {
        db.collection(collection)
            .order(by: "created_at", descending: true)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching todos: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                self.todos = documents.compactMap { document -> Todo? in
                    try? document.data(as: Todo.self)
                }
            }
    }
    
    func addTodo(title: String) {
        let todo = Todo(
            title: title,
            completed: false,
            createdAt: Date()
        )
        
        do {
            _ = try db.collection(collection).addDocument(from: todo)
        } catch {
            print("Error adding todo: \(error.localizedDescription)")
        }
    }
    
    func toggleTodoComplete(todo: Todo) {
        guard let id = todo.id else { return }
        
        let updatedTodo = Todo(
            id: id,
            title: todo.title,
            completed: !todo.completed,
            createdAt: todo.createdAt,
            updatedAt: Date()
        )
        
        do {
            try db.collection(collection).document(id).setData(from: updatedTodo)
        } catch {
            print("Error updating todo: \(error.localizedDescription)")
        }
    }
    
    func deleteTodo(todo: Todo) {
        guard let id = todo.id else { return }
        
        db.collection(collection).document(id).delete { error in
            if let error = error {
                print("Error deleting todo: \(error.localizedDescription)")
            }
        }
    }
} 