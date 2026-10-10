import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import {
  ClothingSlotsState,
  defaultClothingSlots,
  defaultPlayerStatus,
  PlayerStatusState,
} from '../typings/qboxUi';
import type { RootState } from '../store';

const initialState = {
  playerStatus: defaultPlayerStatus,
  clothingSlots: defaultClothingSlots,
};

export const qboxUiSlice = createSlice({
  name: 'qboxUi',
  initialState,
  reducers: {
    setPlayerStatus: (state, action: PayloadAction<Partial<PlayerStatusState>>) => {
      state.playerStatus = {
        ...state.playerStatus,
        ...action.payload,
        config: {
          ...state.playerStatus.config,
          ...(action.payload.config || {}),
        },
      };
    },
    setClothingSlots: (state, action: PayloadAction<ClothingSlotsState>) => {
      state.clothingSlots = action.payload;
    },
  },
});

export const { setPlayerStatus, setClothingSlots } = qboxUiSlice.actions;

export const selectPlayerStatus = (state: RootState) => state.qboxUi.playerStatus;
export const selectClothingSlots = (state: RootState) => state.qboxUi.clothingSlots;
export const selectQboxUiConfig = (state: RootState) => state.qboxUi.playerStatus.config;

export default qboxUiSlice.reducer;
