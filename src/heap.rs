pub struct MinHeap<T: PartialOrd + Clone>(Vec<T>);

fn parent_idx(i: usize) -> usize {
    return (i - 1) / 2;
}
fn left_child_idx(i: usize) -> usize {
    return (2 * i) + 1;
}
fn right_child_idx(i: usize) -> usize {
    return (2 * i) + 2;
}

impl<T: PartialOrd + Clone> MinHeap<T> {
    pub fn new() -> Self {
        Self(Vec::new())
    }

    pub fn len(&self) -> usize {
        self.0.len()
    }

    fn parent_of(&self, i: usize) -> &T {
        return &self.0[(i - 1) / 2];
    }
    fn left_child_of(&self, i: usize) -> Option<&T> {
        let idx = (2 * i) + 1;
        if self.len() <= idx {
            return Option::None;
        }
        return Option::Some(&self.0[idx]);
    }
    fn right_child_of(&self, i: usize) -> Option<&T> {
        let idx = (2 * i) + 2;
        if self.len() <= idx {
            return Option::None;
        }
        return Option::Some(&self.0[idx]);
    }
    fn smallest_child_idx(&self, i: usize) -> Option<usize> {
        match (self.left_child_of(i), self.right_child_of(i)) {
            (Some(left), Some(right)) => {
                if left > right {
                    Some(right_child_idx(i).try_into().unwrap())
                } else {
                    Some(left_child_idx(i).try_into().unwrap())
                }
            }
            (Some(_left), None) => left_child_idx(i).try_into().unwrap(),
            (None, None) => None,
            _ => None,
        }
    }

    fn swap(&mut self, idx_a: usize, idx_b: usize) {
        let aux = self.0[idx_a].clone();
        self.0[idx_a] = self.0[idx_b].clone();
        self.0[idx_b] = aux;
    }

    pub fn hpush(&mut self, val: T) {
        self.0.push(val); // put the value in the end
        let mut i = self.len() - 1;

        while i >= 1 && self.0[i] < *self.parent_of(i) {
            // swap with parent
            self.swap(i, parent_idx(i));
            i = parent_idx(i);
        }
    }

    pub fn hpop(&mut self) -> T {
        let ans = self.0.remove(0); // remove first element(max)
        if self.len() == 0 {
            return ans;
        }

        let last_elem = self.0.pop().unwrap();
        self.0.insert(0, last_elem); // put the last element at the top of the heap

        let mut i = 0;
        while i < self.len() - 1 {
            let smallest_child_idx = self.smallest_child_idx(i);

            // if no child or greater than children, stop
            if smallest_child_idx.is_none() || self.0[i] < self.0[smallest_child_idx.unwrap()] {
                break;
            }

            // swap with smallest child
            self.swap(i, smallest_child_idx.unwrap());
            i = smallest_child_idx.unwrap();
        }

        return ans;
    }
}

// #[cfg(test)] // only test when cargo test is run, not when building
#[cfg(test)]
mod tests {
    use crate::*;

    #[test]
    fn test_hpush() {
        // create new heap
        let mut heap = MinHeap::new();

        heap.hpush(3);
        heap.hpush(2);
        heap.hpush(1);

        assert_eq!(vec![1, 3, 2], heap.0);
    }

    #[test]
    fn test_hpop() {
        // create new heap
        let mut heap = MinHeap::new();

        heap.hpush(7);
        println!("{:?}", heap.0);
        heap.hpush(6);
        println!("{:?}", heap.0);
        heap.hpush(5);
        println!("{:?}", heap.0);
        heap.hpush(4);
        println!("{:?}", heap.0);
        heap.hpush(3);
        println!("{:?}", heap.0);
        heap.hpush(2);
        println!("{:?}", heap.0);
        heap.hpush(1);
        println!("{:?}", heap.0);

        assert_eq!(1, heap.hpop());
        println!("{:?}", heap.0);
        assert_eq!(2, heap.hpop());
        println!("{:?}", heap.0);
        assert_eq!(3, heap.hpop());
        println!("{:?}", heap.0);
        assert_eq!(4, heap.hpop());
        println!("{:?}", heap.0);
        assert_eq!(5, heap.hpop());
        println!("{:?}", heap.0);
        assert_eq!(6, heap.hpop());
        println!("{:?}", heap.0);
        assert_eq!(7, heap.hpop());
        println!("{:?}", heap.0);
    }
}
