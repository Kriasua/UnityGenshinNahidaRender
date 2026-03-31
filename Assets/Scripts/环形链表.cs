using System.Collections;
using System.Collections.Generic;
using UnityEngine;


  public class ListNode {
      public int val;
      public ListNode next;
      public ListNode(int x) {
          val = x;
          next = null;
      }
}


  public class Solution
  {
      public ListNode DetectCycle(ListNode head)
      {
          if (head == null || head.next == null)
          {
              return null;
          }
          
          ListNode slow = head;
          ListNode fast = head;
          

          do
          {
              if (fast == null || fast.next == null)
              {
                  return null; // 无环
              }
              slow = slow.next;
              fast = fast.next.next;
          } while (fast != slow);
          

          fast = head;

          while (fast != slow)
          {
              slow = slow.next;
              fast = fast.next;
          }

          return fast;



      }
  }






  public class 环形链表 : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {

    }

    // Update is called once per frame
    void Update()
    {

    }
}
