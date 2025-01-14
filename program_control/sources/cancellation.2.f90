! @@name:	cancellation.2f
! @@type:	F-free
! @@compilable:	yes
! @@requires:	preprocessing
! @@linkable:	no
! @@expect:	success
! @@version:	omp_5.1
#if _OPENMP  < 202011
#define masked master
#endif

module parallel_search
  type binary_tree
    integer :: value
    type(binary_tree), pointer :: right
    type(binary_tree), pointer :: left
  end type

contains
  recursive subroutine search_tree(tree, value, level, found)
    type(binary_tree), intent(in), pointer :: tree
    integer, intent(in) :: value, level
    type(binary_tree), pointer :: found
    type(binary_tree), pointer :: found_left => NULL(), found_right => NULL()

    if (associated(tree)) then
      if (tree%value .eq. value) then
        found => tree
      else
!$omp task shared(found) if(level<10)
        call search_tree(tree%left, value, level+1, found_left)
        if (associated(found_left)) then
!$omp critical
          found => found_left
!$omp end critical

!$omp cancel taskgroup
        endif
!$omp end task

!$omp task shared(found) if(level<10)
        call search_tree(tree%right, value, level+1, found_right)
        if (associated(found_right)) then
!$omp critical
          found => found_right
!$omp end critical

!$omp cancel taskgroup
        endif
!$omp end task

!$omp taskwait
      endif
    endif
  end subroutine

  subroutine search_tree_parallel(tree, value, found)
    type(binary_tree), intent(in), pointer :: tree
    integer, intent(in) :: value
    type(binary_tree), pointer :: found

    found => NULL()
!$omp parallel shared(found, tree, value)
!$omp masked
!$omp taskgroup
    call search_tree(tree, value, 0, found)
!$omp end taskgroup
!$omp end masked
!$omp end parallel
  end subroutine

end module parallel_search
