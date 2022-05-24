CREATE TABLE [MIDI].[__NullLocations_Archived] (
    [LocationAddress] VARCHAR (18) NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [ucx_Stuff]
    ON [MIDI].[__NullLocations_Archived]([LocationAddress] ASC);

