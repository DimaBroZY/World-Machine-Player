using Godot;
using System;
using System.Collections.Generic;
using System.Linq;
using FuzzySharp;

public partial class TrackSearch : Node
{
    public int[] RankMatches(string[] candidates, string query, int fuzzyThreshold =80)
    {
        query = query.Trim();
        if (string.IsNullOrEmpty(query))
            return Enumerable.Range(0, candidates.Length).ToArray();

        var exact = new List<(int idx, int pos)>();
        var fuzzy = new List<(int idx, int score)>();

        for (int i = 0; i < candidates.Length; i++)
        {
            int pos = candidates[i].IndexOf(query, StringComparison.OrdinalIgnoreCase);
            if (pos >= 0)
            {
                // точное совпадение подстроки - всегда попадает в выдачу
                exact.Add((i, pos));
            }
            else if (query.Length >= 3) 
            {
                int score = Fuzz.WeightedRatio(query, candidates[i]);
                if (score >= fuzzyThreshold)
                    fuzzy.Add((i, score));
            }
        }

        exact.Sort((a, b) => a.pos.CompareTo(b.pos));
        fuzzy.Sort((a, b) => b.score.CompareTo(a.score));

        return exact.Select(e => e.idx).Concat(fuzzy.Select(f => f.idx)).ToArray();
    }
}