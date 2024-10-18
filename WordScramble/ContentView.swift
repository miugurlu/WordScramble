//
//  ContentView.swift
//  WordScramble
//
//  Created by İbrahim Uğurlu on 17.10.2024.
//

import SwiftUI

struct ContentView: View {
    @State private var usedWords = [String]()
    @State private var rootWord = ""
    @State private var newWord = ""
    
    @State private var errorTitle = ""
    @State private var errorMessage = ""
    @State private var showingError = false
    
    @State private var score = 0
    @State private var validWords = [String]()
    @State private var foundWords = 0
    @State private var showingAlert = false
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Enter your word", text: $newWord)
                        .focused($isTextFieldFocused)
                        .textInputAutocapitalization(.never)
                        .onSubmit {
                            addNewWord()
                            isTextFieldFocused = true
                        }
                }
                
                Section {
                    ForEach(usedWords, id: \.self) { word in
                        HStack {
                            Image(systemName: "\(word.count).circle")
                            Text(word)
                        }
                    }
                }
            }
            .navigationTitle(rootWord)
            .onSubmit { addNewWord() }
            .onAppear(perform: nextWord)
            
            Text("Score: \(score)")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            Text("Words: \(foundWords) / \(validWords.count)")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
                .alert(errorTitle, isPresented: $showingError) {
                    Button("OK") {
                        isTextFieldFocused = true
                    }
                } message: {
                    Text(errorMessage)
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Next Word") {
                            nextWord()
                            isTextFieldFocused = true
                        }
                        
                    }
                    ToolbarItem(placement: .primaryAction){
                        Button("Restart"){
                            restart()
                            isTextFieldFocused = true
                        }
                        .alert("Game Restarted", isPresented: $showingAlert) {
                            Button("OK", role: .cancel){}
                        }message: {
                            Text("Your final score was \(score)")
                        }
                    }
                        
                }
        }
    }
    
    func addNewWord() {
        let answer = newWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard answer.count > 0 else { return }
        
        if !isOriginal(word: answer) {
            wordError(title: "Word used already", message: "Be more original")
            score -= 1
            return
        }
        
        if !isPossible(word: answer) {
            wordError(title: "Word not possible", message: "You can't spell that word from '\(rootWord)'!")
            score -= 1
            return
        }
        
        if !isLongEnough(word: answer) {
            wordError(title: "Word is not long enough", message: "You must type at least 3 letters word")
            score -= 1
            return
        }
        
        if !isStartWord(word: answer) {
            wordError(title: "Word is the same as root word", message: "You must type something different than the root word")
            score -= 1
            return
        }
        
        if isReal(word: answer) {
            withAnimation {
                usedWords.insert(answer, at: 0)
                foundWords += 1
            }
            
            if answer.count == rootWord.count {
                score += answer.count * 2
            } else {
                score += answer.count
            }
            
            newWord = ""
        } else {
            wordError(title: "Word not recognized", message: "You can't just make them up, you know!")
            score -= 1
        }
    }
    
    func nextWord() {
        usedWords.removeAll()
        newWord = ""
        foundWords = 0
        
        if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
            if let startWords = try? String(contentsOf: startWordsURL, encoding: .utf8) {
                let allWords = startWords.components(separatedBy: "\n")
                
                if let selectedWord = allWords.randomElement() {
                    let components = selectedWord.components(separatedBy: ":")
                    rootWord = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if components.count > 1 {
                        let validWordList = components[1].components(separatedBy: ",")
                        validWords = validWordList.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    } else {
                        validWords = []
                    }
                }
            }
        } else {
            fatalError("Could not load start.txt from bundle.")
        }
    }
    
    func restart () {
        usedWords.removeAll()
        newWord = ""
        foundWords = 0
        
        showingAlert = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            score = 0
        }
        if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
            if let startWords = try? String(contentsOf: startWordsURL, encoding: .utf8) {
                let allWords = startWords.components(separatedBy: "\n")
                
                if let selectedWord = allWords.randomElement() {
                    let components = selectedWord.components(separatedBy: ":")
                    rootWord = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if components.count > 1 {
                        let validWordList = components[1].components(separatedBy: ",")
                        validWords = validWordList.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    } else {
                        validWords = []
                    }
                }
            }
        } else {
            fatalError("Could not load start.txt from bundle.")
        }
    }
    
    func isOriginal(word: String) -> Bool {
        !usedWords.contains(word)
    }
    
    func isPossible(word: String) -> Bool {
        var tempWord = rootWord
        
        for letter in word {
            if let pos = tempWord.firstIndex(of: letter) {
                tempWord.remove(at: pos)
            } else {
                return false
            }
        }
        return true
    }
    
    func isReal(word: String) -> Bool {
        return validWords.contains(word)
    }
    
    func isLongEnough(word: String) -> Bool {
        word.count > 2
        
    }
    
    func isStartWord(word: String) -> Bool {
        word != rootWord
    }
    
    func wordError(title: String, message: String) {
        errorTitle = title
        errorMessage = message
        showingError = true
    }
    
    func findAllValidWords(from rootWord: String) -> [String] {
        guard let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt"),
              let startWords = try? String(contentsOf: startWordsURL, encoding: .utf8) else {
            return []
        }
        
        let allWords = startWords.components(separatedBy: "\n")
        return allWords.filter { isPossible(word: $0) }
    }
    
}

#Preview {
    ContentView()
}
