import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';

import '../../db_helper/db_helper.dart';
import '../../models/category.dart';
import '../../models/event_message.dart';
import '../../models/tag.dart';
import 'event_screen_event.dart';
import 'event_screen_state.dart';

class EventScreenBloc extends Bloc<EventScreenEvent, EventScreenState> {
  EventScreenBloc(EventScreenState initialState) : super(initialState);

  final DBHelper _dbHelper = DBHelper();
  final Category _emptyCategory = Category(
    nameOfCategory: 'Null',
    imagePath: 'assets/images/journal.png',
  );
  final tagRegExp = RegExp(r'^#[^ !@#$%^&*(),.?":{}|/?\\<>]+$');

  @override
  Stream<EventScreenState> mapEventToState(EventScreenEvent event) async* {
    if (event is EventMessageListInit) {
      yield* _mapEventMessageListInitToState(event);
    } else if (event is EventMessageAdded) {
      yield* _mapEventMessageAddedToState(event);
    } else if (event is UpdateEventMessageList) {
      yield* _mapUpdateToState(event);
    } else if (event is SearchIconButtonUnpressed) {
      yield* _mapSearchIconButtonUnpressedToState(event);
    } else if (event is SearchIconButtonPressed) {
      yield* _mapSearchIconButtonPressedToState(event);
    } else if (event is FavoriteButPressed) {
      yield* _mapFavoriteButPressedToState(event);
    } else if (event is EventMessageListFiltered) {
      yield* _mapEventMessageListFilteredToState(event);
    } else if (event is EventMessageListFilteredReceived) {
      yield* _mapEventMessageListFilteredReceivedToState();
    } else if (event is EventMessageSelected) {
      yield* _mapEventMessageSelectedToState(event);
    } else if (event is SendButtonChanged) {
      yield* _mapSendButtonChangedToState(event);
    } else if (event is EditingModeChanged) {
      yield* _mapEditingModeChangedToState(event);
    } else if (event is CategorySelectedModeChanged) {
      yield* _mapCategorySelectedModeChangedToState(event);
    } else if (event is EventMessageDeleted) {
      yield* _mapEventMessageDeletedToState();
    } else if (event is EventMessageEdited) {
      yield* _mapEventMessageEditedToState(event);
    } else if (event is EventMessageToFavorite) {
      yield* _mapEventMessageToFavoriteToState(event);
    } else if (event is SelectedCategoryAdded) {
      yield* _mapSelectedCategoryAddedToState(event);
    } else if (event is DateSelected) {
      yield* _mapDateSelectedToState(event);
    } else if (event is TimeSelected) {
      yield* _mapTimeSelectedToState(event);
    } else if (event is TagAdded) {
      yield* _mapTagAddedToState(event);
    } else if (event is TagDeleted) {
      yield* _mapTagDeletedToState(event);
    } else if (event is UpdateTagList) {
      yield* _mapUpdateTagListToState();
    } else if (event is CheckEventMessageForTag) {
      yield* _mapCheckEventMessageForTagToState(event);
    }
  }

  Stream<EventScreenState> _mapEventMessageListInitToState(
      EventMessageListInit event) async* {
    add(
      UpdateEventMessageList(event.listViewSuggestion.id),
    );
    yield state.copyWith(
      isSearchIconButtonPressed: false,
      isCategorySelected: false,
      isWriting: false,
      isEditing: false,
      isFavoriteButPressed: false,
      listViewSuggestion: event.listViewSuggestion,
      selectedDate: DateTime.now(),
      selectedTime: TimeOfDay(
        hour: DateTime.now().hour,
        minute: DateTime.now().minute,
      ),
    );
  }

  Stream<EventScreenState> _mapSearchIconButtonUnpressedToState(
      SearchIconButtonUnpressed event) async* {
    yield state.copyWith(
        filteredEventMessageList: event.eventMessageList,
        isSearchIconButtonPressed: !event.isSearchIconButtonPressed);
  }

  Stream<EventScreenState> _mapSearchIconButtonPressedToState(
      SearchIconButtonPressed event) async* {
    yield state.copyWith(
        isSearchIconButtonPressed: !event.isSearchIconButtonPressed);
  }

  Stream<EventScreenState> _mapSendButtonChangedToState(
      SendButtonChanged event) async* {
    yield state.copyWith(isWriting: event.isWriting);
  }

  Stream<EventScreenState> _mapFavoriteButPressedToState(
      FavoriteButPressed event) async* {
    yield state.copyWith(isFavoriteButPressed: !event.isFavoriteButPressed);
  }

  Stream<EventScreenState> _mapEventMessageListFilteredToState(
      EventMessageListFiltered event) async* {
    yield state.copyWith(
        filteredEventMessageList: event.eventMessageList
            .where((suggestion) => suggestion.isImageMessage == 1
                ? 'Image'
                    .toLowerCase()
                    .contains(event.searchEventMessage.toLowerCase())
                : suggestion.text
                    .toLowerCase()
                    .contains(event.searchEventMessage.toLowerCase()))
            .toList());
  }

  Stream<EventScreenState>
      _mapEventMessageListFilteredReceivedToState() async* {
    yield state.copyWith();
  }

  Stream<EventScreenState> _mapEventMessageSelectedToState(
      EventMessageSelected event) async* {
    yield state.copyWith(selectedEventMessage: event.selectedEventMessage);
  }

  Stream<EventScreenState> _mapUpdateToState(
      UpdateEventMessageList event) async* {
    final dbEventMessageList =
        await _dbHelper.dbEventMessagesListForEventScreen(event.idOfSuggestion);
    yield state.copyWith(
      filteredEventMessageList: dbEventMessageList,
      eventMessageList: dbEventMessageList,
    );
  }

  Stream<EventScreenState> _mapEventMessageAddedToState(
      EventMessageAdded event) async* {
    _dbHelper.insertEventMessage(event.eventMessage);
    add(
      UpdateEventMessageList(state.listViewSuggestion.id),
    );
    yield state.copyWith();
  }

  Stream<EventScreenState> _mapEditingModeChangedToState(
      EditingModeChanged event) async* {
    yield state.copyWith(isEditing: event.isEditing);
  }

  Stream<EventScreenState> _mapCategorySelectedModeChangedToState(
      CategorySelectedModeChanged event) async* {
    yield state.copyWith(
      isCategorySelected: !event.isCategorySelected,
      selectedCategory: _emptyCategory,
    );
  }

  Stream<EventScreenState> _mapSelectedCategoryAddedToState(
      SelectedCategoryAdded event) async* {
    yield state.copyWith(
      selectedCategory: event.selectedCategory,
    );
  }

  Stream<EventScreenState> _mapEventMessageToFavoriteToState(
      EventMessageToFavorite event) async* {
    event.eventMessage.isFavorite =
        (event.eventMessage.isFavorite == 1) ? 0 : 1;
    _dbHelper.updateEventMessage(event.eventMessage);
    add(
      UpdateEventMessageList(state.listViewSuggestion.id),
    );
    yield state.copyWith();
  }

  Stream<EventScreenState> _mapEventMessageDeletedToState() async* {
    _dbHelper.deleteEventMessage(state.selectedEventMessage);
    add(
      UpdateEventMessageList(state.listViewSuggestion.id),
    );
    yield state.copyWith();
  }

  Stream<EventScreenState> _mapEventMessageEditedToState(
      EventMessageEdited event) async* {
    final eventMessage = EventMessage(
      id: state.selectedEventMessage.id,
      idOfSuggestion: state.selectedEventMessage.idOfSuggestion,
      time: state.selectedEventMessage.time,
      text: event.editedNameOfEventMessage,
      isFavorite: state.selectedEventMessage.isFavorite,
      imagePath: state.selectedEventMessage.imagePath,
      isImageMessage: state.selectedEventMessage.isImageMessage,
      categoryImagePath: state.selectedEventMessage.categoryImagePath,
      nameOfCategory: state.selectedEventMessage.nameOfCategory,
    );
    _dbHelper.updateEventMessage(eventMessage);
    add(
      UpdateEventMessageList(state.listViewSuggestion.id),
    );
    yield state.copyWith(selectedEventMessage: eventMessage);
  }

  Stream<EventScreenState> _mapDateSelectedToState(DateSelected event) async* {
    yield state.copyWith(selectedDate: event.selectedDate);
  }

  Stream<EventScreenState> _mapTimeSelectedToState(TimeSelected event) async* {
    yield state.copyWith(selectedTime: event.selectedTime);
  }

  Stream<EventScreenState> _mapCheckEventMessageForTagToState(
      CheckEventMessageForTag event) async* {
    final eventMessageWordList = event.eventMessageText.split(RegExp(r'[ ]+'));
    final tagTextList = state.tagList.map((tag) => tag.tagText).toList();

    for (final word in eventMessageWordList) {
      if (tagRegExp.hasMatch(word) && !tagTextList.contains(word)) {
        add(
          TagAdded(
            Tag(tagText: word),
          ),
        );
      }
    }
    yield state.copyWith();
  }

  Stream<EventScreenState> _mapTagAddedToState(TagAdded event) async* {
    _dbHelper.insertTag(event.tag);
    add(UpdateTagList());
    yield state.copyWith();
  }

  Stream<EventScreenState> _mapTagDeletedToState(TagDeleted event) async* {
    _dbHelper.deleteTag(event.tag);
    add(UpdateTagList());
    yield state.copyWith();
  }

  Stream<EventScreenState> _mapUpdateTagListToState() async* {
    final dbTagList = await _dbHelper.dbTagList();
    yield state.copyWith(
      tagList: dbTagList,
    );
  }
}
