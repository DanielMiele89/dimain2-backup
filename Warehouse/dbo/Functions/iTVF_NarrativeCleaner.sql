CREATE FUNCTION [dbo].[iTVF_NarrativeCleaner] 
	(@ID INT, @Narrative_Cleaned VARCHAR(250))

RETURNS TABLE AS RETURN (

	SELECT TOP(1) 
		cl.ID, 
		Narrative_Cleaned = LTRIM(nc_2.Narrative_Cleaned),
		cl.IsPrefixRemoved
	FROM Warehouse.Staging.CTLoad_MIDINarrativeCleanup cl
	CROSS APPLY (
		SELECT 
			TextToReplace = Replace(cl.TextToReplace, '%', ''),
			TextToReplacejoin = cl.TextToReplace,
			TextToReplace_NoSpaces = Replace(Replace(cl.TextToReplace, '%', ''), ' ', ''),
			TextToReplacejoin_NoSpaces = Replace(cl.TextToReplace, ' ', ''),
			NarrativeNotLike = cl.NarrativeNotLike,
			IsPrefixRemoved = cl.IsPrefixRemoved
	) q

	CROSS APPLY (SELECT Narrative_Cleaned = LTrim(RTrim(Replace(Replace(Replace(@Narrative_Cleaned, ' ', '<>'), '><', ''), '<>', ' ')))) d

	CROSS APPLY (Select Case
							When (d.Narrative_Cleaned Like q.TextToReplacejoin Or d.Narrative_Cleaned Like q.TextToReplacejoin_NoSpaces) 
									Then LTrim(RTrim(Replace(Replace(Replace(Replace(Replace(Narrative_Cleaned, q.TextToReplace, ''), q.TextToReplace_NoSpaces, ''), ' ', '<>'), '><', ''), '<>', ' ')))
							Else d.Narrative_Cleaned
						End as Narrative_Cleaned) nc_1

	CROSS APPLY (Select Case
							When Left(nc_1.Narrative_Cleaned, 1) In ('-', '*') 
									Then Ltrim(Right(nc_1.Narrative_Cleaned, Len(nc_1.Narrative_Cleaned) - 1))
									--THEN nc_1.Narrative_Cleaned
							Else nc_1.Narrative_Cleaned
						End as Narrative_Cleaned) nc_2

	WHERE LiveRule = 1
		AND (d.Narrative_Cleaned Like q.TextToReplacejoin Or d.Narrative_Cleaned Like q.TextToReplacejoin_NoSpaces)
		AND d.Narrative_Cleaned Not Like q.NarrativeNotLike
		AND ID > @ID
	ORDER BY cl.ID

	)