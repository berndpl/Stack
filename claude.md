# Stack App

An app for iPad and macOS

A 2D canvas to help explore and evaluate differently composed prompts LLM model chains and how they affect the reponse.

Default set up
- PromptCard
- LLMCard (Ollama)

Story: Run Prompt
- Tap generate on LLMCard to run prompt
- 

How it works

A prompt is composed by multiple pieces of text, each placed in it's own PromptCard. Each card is automatically connected and put into sequence. The conent is combined and submitted to the LLMCard

I can add multiple PromptCards to section the prompt.

I can also quickly mute a PromptCard to remove it from the compiled prompt without deleting the content. This helps me to quickly A/B test.

Card Behaviour

Cards appear as a stack. Each card has a slight offset so you can see its header. 

You can tap the card header to expand the stack so you can see and edit its content

Interface

PrompCard
- Mute button
- Textview
- Add to sequence button

LLMCard
- OllamaCard: 
    - Exandable Input preview
    - Textfield for URL of local Ollama address, 
    - Textfield with string of model to use
    - Generate button
  
Top Level
- Primary action is a Play button to run a stack 

---

## Comparison Interaction

Comparing alternative versions.

When tapping "Compare", the current stack is duplicated.
All cards are linked to the ordignal cards. until any attributes are overidden
Cards that are linked appear with 0.6 opacity
Cards with customized attributes show with full opacity

There is a separate play button at the bottom of each stack that allows running it.

The main play button at the bottom runs all stacks at once with a stingle press.


--

## Data Model

Pay special attention to the data structure to create a relatable easy to maintain structure

There are 4 main data model types defines as structs, 3 Types of Cards and Stacks. 

+ Prompt Card
+ LLM Card
+ Response Card
+ Stack
 - Linking to all cards in a Stack



---

Setup

Let's make things a bit modular

- Separate View with Previews for
CardLLMView
CardPromptView
CardResponseView

- A CardCoordinator where used cards and their the sequence is managed and stored
