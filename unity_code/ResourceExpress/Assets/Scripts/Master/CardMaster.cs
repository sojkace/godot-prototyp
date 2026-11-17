using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class CardMaster : MonoBehaviour
{
    public static CardMaster instance { get; private set; }

    [Header("Decks")]
    public List<Card> attackDeck;
    public List<Card> railDeck;
    public List<Card> specialDeck;

    [Header("Resources")]
    [SerializeField]
    private List<Resources> attackDeckResources;
    [SerializeField]
    private List<Resources> railDeckResources;
    [SerializeField]
    private List<Resources> specialDeckResources;

    [Header("Holder")]
    [SerializeField]
    private Transform attackDeckHolder;
    [SerializeField]
    private Transform railDeckHolder;
    [SerializeField]
    private Transform specialDeckHolder;
    [SerializeField]
    private Transform playedCardsHolder;
    [SerializeField]
    private Transform studioPosOfAttackBu;
    [SerializeField]
    private Transform studioPosOfRailBu;
    [SerializeField]
    private Transform studioPosOfSpecialBu;

    [Header("Textures")]
    [SerializeField]
    private RenderTexture attackDeckRender;
    [SerializeField]
    private RenderTexture railDeckRender;
    [SerializeField]
    private RenderTexture specialDeckRender;

    private List<Card> playedCards = new List<Card>();
    private Card currentAttackCard;
    private Card currentRailCard;
    private Card currentSpecialCard;
    private void Awake()
    {
        if (instance != null && instance != this)
        {
            Debug.Log("CaardMaster exist more then ones");
            Destroy(this);
        }
        else
        {
            instance = this;
        }
    }
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    public void SetUpCards(List<Card> newAttackDeck, List<Card> newRailDeck, List<Card> newspecialDeck)
    {
        DestroyAllCards();
        foreach (Card card in newAttackDeck)
        {
            Card newCard = Instantiate(card, attackDeckHolder);
            newCard.deck = "Attack";
            attackDeck.Add(newCard);
            newCard.SetUp();
            SetUpTextureForCard(newCard);
            newCard.gameObject.SetActive(false);
        }
        attackDeck = ShuffleDeck(attackDeck);
        currentAttackCard = attackDeck[0];
        currentAttackCard.gameObject.SetActive(true);

        foreach (Card card in newRailDeck)
        {
            Card newCard = Instantiate(card, railDeckHolder);
            newCard.deck = "Rail";
            railDeck.Add(newCard);
            newCard.SetUp();
            SetUpTextureForCard(newCard);
            newCard.gameObject.SetActive(false);
        }
        railDeck = ShuffleDeck(railDeck);
        currentRailCard = railDeck[0];
        currentRailCard.gameObject.SetActive(true);

        foreach (Card card in newspecialDeck)
        {
            Card newCard = Instantiate(card, specialDeckHolder);
            newCard.deck = "Special";
            specialDeck.Add(newCard);
            newCard.SetUp();
            SetUpTextureForCard(newCard);
            newCard.gameObject.SetActive(false);
        }
        specialDeck = ShuffleDeck(specialDeck);
        currentSpecialCard = specialDeck[0];
        currentSpecialCard.gameObject.SetActive(true);

        UpdateTable();
    }

    private void SetUpTextureForCard(Card card)
    {
        if (attackDeck.Contains(card))
        {
            card.image.texture = attackDeckRender;
            foreach(Transform transform in studioPosOfAttackBu)
            {
                Destroy(transform.gameObject);
            }
            Instantiate(card.buildingToBuild, studioPosOfAttackBu);
        }
        if (railDeck.Contains(card))
        {
            card.image.texture = railDeckRender;
            foreach (Transform transform in studioPosOfRailBu)
            {
                Destroy(transform.gameObject);
            }
            Instantiate(card.buildingToBuild, studioPosOfRailBu);
        }
        if (specialDeck.Contains(card))
        {
            card.image.texture = specialDeckRender;
            foreach (Transform transform in studioPosOfSpecialBu)
            {
                Destroy(transform.gameObject);
            }
            Instantiate(card.buildingToBuild, studioPosOfSpecialBu);
        }
        
    }

    public void CardClicked(Card card)
    {
        if (CheckIfEnoughResForCard(card))
        {
            RemoveItemsForCard(card);
            MoveCardToDeck(card, playedCards);
            card.gameObject.SetActive(false);
            card.transform.SetParent(playedCardsHolder);
            BuildingMaster.instance.StartBuildingWithObj(card.buildingToBuild);
            currentAttackCard = attackDeck[0];
            currentRailCard = railDeck[0];
            currentSpecialCard = specialDeck[0];
            UpdateTable();
        }
    }

    void MoveCardToDeck(Card card, List<Card> deck)
    {
        if (attackDeck.Contains(card))
        {
            deck.Add(card);
            attackDeck.Remove(card);
        }
        if (railDeck.Contains(card))
        {
            deck.Add(card);
            railDeck.Remove(card);
        }
        if (specialDeck.Contains(card))
        {
            deck.Add(card);
            specialDeck.Remove(card);
        }
        if (playedCards.Contains(card))
        {
            deck.Add(card);
            playedCards.Remove(card);
        }

        if(deck == attackDeck)
        {
            card.deck = "Attack";
        }
        if(deck == railDeck)
        {
            card.deck = "Rail";
        }
        if(deck == specialDeck)
        {
            card.deck = "Special";
        }
        if(deck == playedCards)
        {
            card.deck = "Played";
        }
    }

    void DestroyAllCards()
    {
        foreach (Card card in attackDeck)
        {
            Destroy(card);
        }
        attackDeck.Clear();
        foreach (Card card in railDeck)
        {
            Destroy(card);
        }
        railDeck.Clear();
        foreach(Card card in specialDeck)
        {
            Destroy(card);
        }
        specialDeck.Clear();
    }

    public void UpdateTable()
    {
        currentAttackCard.gameObject.SetActive(true);
        SetUpTextureForCard(currentAttackCard);
        currentRailCard.gameObject.SetActive(true);
        SetUpTextureForCard(currentRailCard);
        currentSpecialCard.gameObject.SetActive(true);
        SetUpTextureForCard(currentSpecialCard);
        foreach (Resources r in attackDeckResources)
        {
            r.UpdateUI();
            if (CheckIfEnoughResForCard(currentAttackCard))
            {
                currentAttackCard.SetCardState(true);
            }
            else
            {
                currentAttackCard.SetCardState(false);
            }
        }

        foreach (Resources r in railDeckResources)
        {
            r.UpdateUI();
            if (CheckIfEnoughResForCard(currentRailCard))
            {
                currentRailCard.SetCardState(true);
            }
            else
            {
                currentRailCard.SetCardState(false);
            }
        }
        foreach (Resources r in specialDeckResources)
        {
            r.UpdateUI();
            if (CheckIfEnoughResForCard(currentSpecialCard))
            {
                currentSpecialCard.SetCardState(true);
            }
            else
            {
                currentSpecialCard.SetCardState(false);
            }
        }
    }

    bool CheckIfEnoughResForCard(Card card)
    {
        List<bool> enough = new List<bool>();
        if (attackDeck.Contains(card))
        {
            foreach (Resources r in attackDeckResources)
            {
                enough.Add(r.enough);
            }
        }
        if (railDeck.Contains(card))
        {
            foreach (Resources r in railDeckResources)
            {
                enough.Add(r.enough);
            }
        }
        if (specialDeck.Contains(card))
        {
            foreach (Resources r in specialDeckResources)
            {
                enough.Add(r.enough);
            }
        }

        foreach(bool e in enough)
        {
            if (!e)
            {
                return false;
            }
        }

        return true;
    }


    public List<Card> ShuffleDeck(List<Card> deck)
    {
        for (int i = deck.Count - 1; i > 0; i--)
        {
            int j = Random.Range(0, i + 1);
            Card temp = deck[i];
            deck[i] = deck[j];
            deck[j] = temp;
        }
        return deck;
    }

    void RemoveItemsForCard(Card card)
    {
        if (attackDeck.Contains(card))
        {
            foreach(Resources r in attackDeckResources)
            {
                ItemMaster.instance.RemoveItem(r.type, 1);
                UpdateTable();
            }
        }
        if (railDeck.Contains(card))
        {
            foreach (Resources r in railDeckResources)
            {
                ItemMaster.instance.RemoveItem(r.type, 1);
                UpdateTable();
            }
        }
        if (specialDeck.Contains(card))
        {
            foreach (Resources r in specialDeckResources)
            {
                ItemMaster.instance.RemoveItem(r.type, 1);
                UpdateTable();
            }
        }
    }
}
