CREATE TABLE [Relational].[BookingCal_Dim_StandardSegment] (
    [SegementID]         VARCHAR (6)   NOT NULL,
    [SegmentDescription] VARCHAR (100) NULL,
    [DataDescription]    VARCHAR (500) NULL,
    PRIMARY KEY CLUSTERED ([SegementID] ASC)
);

