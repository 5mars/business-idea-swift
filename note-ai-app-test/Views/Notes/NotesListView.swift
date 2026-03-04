//
//  NotesListView.swift
//  note-ai-app-test
//
//  Created by Claude on 2026-03-03.
//

import SwiftUI

struct NotesListView: View {
    @StateObject private var viewModel = NotesViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.notes.isEmpty {
                    ProgressView("Loading notes...")
                } else if viewModel.notes.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "mic.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("No recordings yet")
                            .font(.title2)
                            .foregroundColor(.secondary)

                        Text("Tap the Record tab to create your first voice note")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    List {
                        ForEach(viewModel.notes) { note in
                            NavigationLink(destination: NoteDetailView(note: note)) {
                                NoteRowView(note: note, viewModel: viewModel)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let note = viewModel.notes[index]
                                Task {
                                    await viewModel.deleteNote(note)
                                }
                            }
                        }
                    }
                    .refreshable {
                        await viewModel.fetchNotes()
                    }
                }
            }
            .navigationTitle("Voice Notes")
            .toolbar {
                if !viewModel.notes.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        EditButton()
                    }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .task {
                await viewModel.fetchNotes()
            }
        }
    }
}

struct NoteRowView: View {
    let note: VoiceNote
    let viewModel: NotesViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.title)
                .font(.headline)

            HStack {
                Image(systemName: "waveform")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(viewModel.formatDuration(note.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(note.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NotesListView()
}
