# Fresh Eyes Techniques

Your brain fills in gaps and sees what you intended, not what you wrote. Break this pattern:

## 1. Time Gap (10+ Minutes)

**Why**: Your brain needs to "forget" what you meant to write.

**How**:
- Write code
- Commit to staging: `git add .`
- Take a break (coffee, walk, different task)
- Return and review `git diff --staged` with fresh perspective

## 2. Context Switch

**Why**: Breaking mental context reveals assumptions and gaps.

**How**:
- Work on feature A
- Switch to different task for 15+ minutes
- Return to feature A for review
- Notice things you missed while "in the zone"

## 3. Read Aloud

**Why**: Speaking forces slower, more deliberate processing.

**How**:
- Read your code out loud
- Explain what each section does
- If you stumble or have to re-read, that's a red flag
- Simplify or add comments to clarify

**Example:**
```python
# Hard to read aloud without stumbling
data = [x for x in map(lambda y: y**2 if y%2 else y**3, filter(lambda z: z>0, vals))]

# Easy to read aloud
positive_values = [v for v in vals if v > 0]
data = [v**2 if v % 2 else v**3 for v in positive_values]
```

## 4. Rubber Duck Debugging

**Why**: Teaching forces you to be explicit about logic and assumptions.

**How**:
- Explain the code to an imaginary colleague (or rubber duck)
- Walk through the logic step by step
- Justify each decision
- Often reveals bugs during explanation

**Template:**
```
"This function takes [X] and returns [Y].
First it validates [Z] because...
Then it processes [A] by...
The tricky part is [B] which handles the case where...
It could fail if [C], which we handle by...
I chose this approach over [D] because..."
```

## 5. Reverse Review

**Why**: Breaking narrative flow reveals bugs your brain glosses over.

**How**:
- Start reading from the LAST line of the diff
- Work backwards to the first line
- Breaks the "story" your brain constructed
- Forces evaluation of each line independently
