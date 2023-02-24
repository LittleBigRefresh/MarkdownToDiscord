using System.Text.RegularExpressions;
using MarkdownToDiscord.Elements;

namespace MarkdownToDiscord;

public partial class MarkdownParser
{
    public MarkdownParser(List<string> lines)
    {
        this._lines = lines;
    }

    [GeneratedRegex(@"\[([^\]]+)\]\(([^)]+)\)")]
    private static partial Regex LinkRegex();
    
    [GeneratedRegex(@"!\[([^\]]+)\]\(([^)]+)\)")]
    private static partial Regex ImageRegex();

    private readonly List<string> _lines;

    public IEnumerable<IMarkdownElement> Parse()
    {
        foreach (string lineImmutable in this._lines)
        {
            string line = lineImmutable;
            IMarkdownElement? element = null;
    
            foreach (Match match in ImageRegex().Matches(line))
            {
                string altText = match.Groups[1].Value;
                string linkText = match.Groups[2].Value;
        
                element = new ImageMarkdownElement(linkText, altText);
            }

            if (line.StartsWith("# ")) 
                element = new HeaderMarkdownElement(line.Substring(2));

            if(element != null)
            {
                yield return element;
                continue;
            }

            foreach (Match match in LinkRegex().Matches(line))
            {
                string altText = match.Groups[1].Value;
                string linkText = match.Groups[2].Value;
        
                line = line.Replace(match.Groups[0].Value, $"{altText}: <{linkText}>");
            }

            element = new TextMarkdownElement(line);
            yield return element;
        }
    }
}