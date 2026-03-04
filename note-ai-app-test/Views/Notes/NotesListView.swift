//
//  NotesListView.swift
//  note-ai-app-test
//

import SwiftUI

struct NotesListView: View {
    @StateObject private var viewModel = NotesViewModel()

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            Group {
                if viewModel.isLoading && viewModel.notes.isEmpty {
                    loadingView
                } else if viewModel.notes.isEmpty {
                    emptyStateView
                } else {
                    notesList
                }
            }
        }
        .navigationTitle("Voice Notes")
        .toolbarBackground(Color.appBg, for: .navigationBar)
        .toolbar {
            if !viewModel.notes.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                        .tint(.brand)
                }
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            if let error = viewModel.errorMessage { Text(error) }
        }
        .task { await viewModel.fetchNotes() }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.brand)
                .scaleEffect(1.2)
            Text("Loading notes...")
                .font(.system(size: 15))
                .foregroundColor(.textSec)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.brand.opacity(0.08))
                    .frame(width: 110, height: 110)

                Image(systemName: "mic.slash.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.brand.opacity(0.4), Color.brandLight.opacity(0.3)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
            }

            Text("No recordings yet")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.textPri)

            Text("Tap the Record tab to create\nyour first voice note")
                .font(.system(size: 15))
                .foregroundColor(.textSec)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
        }
        .padding(.horizontal, 40)
    }

    // MARK: - Notes List

    private var notesList: some View {
        List {
            ForEach(viewModel.notes) { note in
                NavigationLink(destination: NoteDetailView(note: note)) {
                    NoteRowView(note: note, viewModel: viewModel)
                }
                .listRowBackground(Color.appBg)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let note = viewModel.notes[index]
                    Task { await viewModel.deleteNote(note) }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable { await viewModel.fetchNotes() }
    }
}

// MARK: - Note Row Card

struct NoteRowView: View {
    let note: VoiceNote
    let viewModel: NotesViewModel

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient.brand)
                    .frame(width: 48, height: 48)

                Image(systemName: "waveform")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            .shadow(color: Color.brand.opacity(0.3), radius: 6, x: 0, y: 3)

            // Info
            VStack(alignment: .leading, spacing: 5) {
                Text(note.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPri)
                    .lineLimit(1)

                HStack(spacing: 10) {
                    Label(viewModel.formatDuration(note.duration), systemImage: "clock")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.brand.opacity(0.7))
                        .labelStyle(.titleAndIcon)

                    Text(note.createdAt, style: .relative)
                        .font(.system(size: 12))
                        .foregroundColor(.textSec)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color.textSec.opacity(0.4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.cardBg)
        .cornerRadius(18)
        .shadow(color: Color.brand.opacity(0.07), radius: 12, x: 0, y: 4)
    }
}

#Preview {
    NavigationStack {
        NotesListView()
    }
}
