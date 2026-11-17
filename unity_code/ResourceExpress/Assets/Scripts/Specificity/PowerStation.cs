using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;

public class PowerStation : Building
{
    [Header("Animator for PowerStation")]
    [SerializeField]
    private Animator coin;
    [SerializeField]
    private Animator heart;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }


    // start Coin Animation and wait for it
    public IEnumerator StartCoinAnimation()
    {
        coin.GetComponent<MeshRenderer>().enabled = true;
        coin.Play("Turn");
        yield return new WaitForSeconds(coin.runtimeAnimatorController.animationClips[0].length);
        coin.GetComponent<MeshRenderer>().enabled = false;
    }

    // start Heart Animation and wait for it
    public IEnumerator StartHeartAnimation()
    {
        heart.GetComponent<MeshRenderer>().enabled = true;
        heart.Play("heartBrok");
        yield return new WaitForSeconds(heart.runtimeAnimatorController.animationClips[0].length);
        heart.GetComponent<MeshRenderer>().enabled = false;
    }
}
