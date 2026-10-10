import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { defaultPlayerStatus, PlayerStatusState } from '../typings/qboxUi';
import type { RootState } from '../store';

const initialState = {
  playerStatus: defaultPlayerStatus,
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
  },
});

export const { setPlayerStatus } = qboxUiSlice.actions;

export const selectPlayerStatus = (state: RootState) => state.qboxUi.playerStatus;
export const selectQboxUiConfig = (state: RootState) => state.qboxUi.playerStatus.config;

export default qboxUiSlice.reducer;
