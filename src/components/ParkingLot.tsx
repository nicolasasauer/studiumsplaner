import React, { useState } from 'react';
import { Droppable } from 'react-beautiful-dnd';
import { AlertCircle } from 'lucide-react';
import { useStudyPlanStore } from '../store';
import { LectureCard } from './LectureCard';

interface ParkingLotProps {
  onEdit: (lectureId: string) => void;
}

export const ParkingLot: React.FC<ParkingLotProps> = ({ onEdit }) => {
  const [isCollapsed, setIsCollapsed] = useState(false);
  const parkingLot = useStudyPlanStore(state => state.parkingLot);

  return (
    <div className="card-hover">
      <button
        onClick={() => setIsCollapsed(!isCollapsed)}
        className="w-full text-left"
      >
        <div className="flex items-center gap-3">
          <AlertCircle size={24} className="text-yellow-400 flex-shrink-0" />
          <div className="flex-1">
            <h2 className="text-xl font-bold text-white">Parkplatz</h2>
            <p className="text-sm text-gray-400">
              {parkingLot.length} Veranstaltung{parkingLot.length !== 1 ? 'en' : ''} mit unklarem Semester
            </p>
          </div>
          {parkingLot.length > 0 && (
            <div className={`transition-transform flex-shrink-0 ${isCollapsed ? '-rotate-90' : ''}`}>
              ▼
            </div>
          )}
        </div>
      </button>

      {!isCollapsed && parkingLot.length > 0 && (
        <Droppable droppableId="parking-lot" type="LECTURE">
          {(provided, snapshot) => (
            <div
              ref={provided.innerRef}
              {...provided.droppableProps}
              className={`p-4 rounded-lg border-2 border-dashed transition-colors ${
                snapshot.isDraggingOver
                  ? 'border-yellow-400 bg-yellow-500/10'
                  : 'border-yellow-600/50 bg-yellow-500/5'
              }`}
            >
              {parkingLot.map((lecture, index) => (
                <LectureCard
                  key={lecture.id}
                  lecture={lecture}
                  index={index}
                  onEdit={() => onEdit(lecture.id)}
                />
              ))}
              {provided.placeholder}
            </div>
          )}
        </Droppable>
      )}
    </div>
  );
};
