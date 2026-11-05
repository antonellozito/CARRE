! NCAR Autograph replacement for the Python graphics of carre.exe: the
! Autograph routines used by Carre2 draw through the NCAR replacement of
! B2.5 (src/b2plot/py/ncar_py.F), which sends them to the Python graphics

      module autograph_py
      implicit none
! Grid window (fractions of the frame), logarithmic axes
      real, save :: grid_l = 0.15, grid_r = 0.95, grid_b = 0.15, &
     &  grid_t = 0.95
      integer, save :: xlog = 0, ylog = 0
! Numeric labels of the bottom (1) and left (2) axes: type, width of
! the characters (fraction of the smaller side of the grid window),
! major tick count of the spacing rule
      integer, save :: numtyp(2) = 1
      real, save :: numwid(2) = 0.015, majcnt(2) = 6.
! Plotchar size of the Python graphics for a GKS character height, as
! GKS text in lib/python/scene.py: Autograph writes through PWRIT
      real, parameter :: gkssiz = 1./(0.7*1.83)
! Informational labels T (top), B (bottom), L (left)
      character*1, save :: lbname = ' '
      character*256, save :: lbtext(3) = ' '
      real, save :: lbwid(3) = 0.015, lbang(3) = 0.
! Dash patterns of AGCURV
      integer, parameter :: ndshmx = 26
      integer, save :: ndsh = 0
      character*64, save :: dshpat(ndshmx) = ' '
      real, save :: dshchr = 0.01
! SET call of the last AGSTUP, number of major intervals of its axes
      real, save :: set_v(4) = (/ 0., 1., 0., 1. /), &
     &  set_w(4) = (/ 0., 1., 0., 1. /)
      integer, save :: set_lf = 1, nmajor(2) = 1, nminor(2) = 5
! Parameter names already reported
      integer, save :: nunknown = 0
      character*48, save :: unknown(32) = ' '

      contains

! Parameter name in upper case without blanks
      function agpy_key(pnam) result(key)
      implicit none
      character*(*), intent(in) :: pnam
      character*48 key
      integer i, j, ic
      key = ' '
      j = 0
      do i = 1, len_trim(pnam)
        ic = iachar(pnam(i:i))
        if (ic.eq.32) cycle
        if (ic.ge.iachar('a').and.ic.le.iachar('z')) ic = ic-32
        j = j+1
        if (j.le.len(key)) key(j:j) = achar(ic)
      end do
      return
      end function agpy_key

! Index of a label name, 0 for labels not drawn
      integer function agpy_label(name)
      implicit none
      character*1, intent(in) :: name
      select case (name)
      case ('T','t')
        agpy_label = 1
      case ('B','b')
        agpy_label = 2
      case ('L','l')
        agpy_label = 3
      case default
        agpy_label = 0
      end select
      return
      end function agpy_label

! Report a parameter that is not emulated, once
      subroutine agpy_unknown(key)
      implicit none
      character*(*), intent(in) :: key
      integer i
      do i = 1, nunknown
        if (unknown(i).eq.key) return
      end do
      if (nunknown.lt.size(unknown)) then
        nunknown = nunknown+1
        unknown(nunknown) = key
      end if
      write(*,'(a)') 'autograph_py: parameter '//trim(key)// &
     &  ' not emulated'
      return
      end subroutine agpy_unknown

! Store a real parameter value
      subroutine agpy_setr(pnam,val)
      implicit none
      character*(*), intent(in) :: pnam
      real, intent(in) :: val
      character*48 key
      integer il
      key = agpy_key(pnam)
      il = agpy_label(lbname)
      select case (key)
      case ('GRID/LEFT.')
        grid_l = val
      case ('GRID/RIGHT.')
        grid_r = val
      case ('GRID/BOTTOM.')
        grid_b = val
      case ('GRID/TOP.')
        grid_t = val
      case ('X/LOGARITHMIC.')
        xlog = nint(val)
      case ('Y/LOGARITHMIC.')
        ylog = nint(val)
      case ('AXIS/BOTTOM/NUMERIC/TYPE.')
        numtyp(1) = nint(val)
      case ('AXIS/LEFT/NUMERIC/TYPE.')
        numtyp(2) = nint(val)
      case ('AXIS/BOTTOM/NUMERIC/WIDTH/MAN.')
        numwid(1) = val
      case ('AXIS/LEFT/NUMERIC/WIDTH/MAN.')
        numwid(2) = val
      case ('AXIS/BOTTOM/MAJOR/COUNT.')
        majcnt(1) = val
      case ('AXIS/LEFT/MAJOR/COUNT.')
        majcnt(2) = val
      case ('LINE/CHARACTER.')
        if (il.gt.0) lbwid(il) = val
      case ('LABEL/ANGLE.')
        if (il.gt.0) lbang(il) = val
      case ('DASH/SELECTOR.')
        ndsh = max(0,min(nint(val),ndshmx))
      case ('DASH/CHARACTER.')
        dshchr = val
! Drawn in the same way whatever their value
      case ('WINDOW.','LINE/NUMBER.','DASH/LENGTH.', &
     &  'AXIS/BOTTOM/NUMERIC/ANGLE/1ST.', &
     &  'AXIS/BOTTOM/NUMERIC/ANGLE/2ND.', &
     &  'AXIS/LEFT/NUMERIC/ANGLE/1ST.','AXIS/LEFT/NUMERIC/ANGLE/2ND.', &
     &  'AXIS/BOTTOM/NUMERIC/WIDTH/EXP.','AXIS/LEFT/NUMERIC/WIDTH/EXP.')
      case default
        call agpy_unknown(key)
      end select
      return
      end subroutine agpy_setr

! Nice axis ends at major ticks: ends lo and hi, number of intervals,
! minor intervals per major one
      subroutine agpy_nice(dmin,dmax,logs,count,lo,hi,nint_out,nmnr)
      implicit none
      real, intent(in) :: dmin, dmax, count
      integer, intent(in) :: logs
      real, intent(out) :: lo, hi
      integer, intent(out) :: nint_out, nmnr
      real a, b, d, mag, f, s
      a = min(dmin,dmax)
      b = max(dmin,dmax)
      nmnr = 5
      if (logs.ne.0) then
        a = max(a,tiny(a))
        b = max(b,a)
        lo = 10.**floor(log10(a)+1.e-5)
        hi = 10.**ceiling(log10(b)-1.e-5)
        if (hi.le.lo) hi = 10.*lo
        nint_out = max(1,nint(log10(hi/lo)))
        return
      end if
      if (b.le.a) then
        d = max(abs(a),1.)
        a = a-0.5*d
        b = b+0.5*d
      end if
! Spacing as AGEXAX: the largest of 10, 5, 2, 1 times a power of ten
! not above the range over COUNT+1, with 1, 4, 1, 1 minor ticks
      d = (b-a)/real(max(0,int(count))+1)
      mag = 10.**floor(log10(d)+1.e-6)
      f = d/mag*(1.+1.e-6)
      nmnr = 2
      if (f.ge.10.) then
        s = 10.*mag
      else if (f.ge.5.) then
        s = 5.*mag
        nmnr = 5
      else if (f.ge.2.) then
        s = 2.*mag
      else
        s = mag
      end if
      lo = s*floor(a/s+1.e-5)
      hi = s*ceiling(b/s-1.e-5)
      if (hi.le.lo) hi = lo+s
      nint_out = max(1,nint((hi-lo)/s))
      return
      end subroutine agpy_nice

! Fortran format of the numeric labels of an axis
      function agpy_format(iax) result(fmt)
      implicit none
      integer, intent(in) :: iax
      character*16 fmt
      real s
      integer nd
      if (numtyp(iax).ne.3) then
        fmt = '(1pe10.2)'
        return
      end if
      if (iax.eq.1) then
        s = abs(set_w(2)-set_w(1))/real(nmajor(1))
      else
        s = abs(set_w(4)-set_w(3))/real(nmajor(2))
      end if
      nd = max(0,-floor(log10(max(s,tiny(s)))+1.e-4))
      if (nd.eq.0) then
        fmt = '(i8)'
      else
        write(fmt,'(a,i0,a,i0,a)') '(f', nd+8, '.', nd, ')'
      end if
      return
      end function agpy_format

! Text of a label up to its terminating dollar sign
      function agpy_text(text) result(line)
      implicit none
      character*(*), intent(in) :: text
      character*256 line
      integer i
      i = index(text,'$')
      if (i.eq.0) then
        line = text
      else if (i.eq.1) then
        line = ' '
      else
        line = text(1:i-1)
      end if
      return
      end function agpy_text

      end module autograph_py

      subroutine agseti(pnam,ival)
      use autograph_py
      implicit none
      character*(*) pnam
      integer ival
      call agpy_setr(pnam,real(ival))
      return
      end subroutine agseti

      subroutine agsetr(pnam,rval)
      use autograph_py
      implicit none
      character*(*) pnam
      real rval
      call agpy_setr(pnam,rval)
      return
      end subroutine agsetr

      subroutine agsetf(pnam,fval)
      use autograph_py
      implicit none
      character*(*) pnam
      real fval
      call agpy_setr(pnam,fval)
      return
      end subroutine agsetf

      subroutine agsetc(pnam,cval)
      use autograph_py
      implicit none
      character*(*) pnam, cval
      character*48 key
      integer il, n, ios
      key = agpy_key(pnam)
      il = agpy_label(lbname)
      if (key.eq.'LABEL/NAME.') then
        lbname = cval(1:1)
      else if (key.eq.'LINE/TEXT.') then
        if (il.gt.0) lbtext(il) = cval
      else if (key(1:13).eq.'DASH/PATTERN/') then
        n = 0
        read(key(14:index(key,'.')-1),*,iostat=ios) n
        if (ios.eq.0.and.n.ge.1.and.n.le.ndshmx) dshpat(n) = cval
      else
        call agpy_unknown(key)
      end if
      return
      end subroutine agsetc

! Name of the parameter of dash pattern n
      character*16 function agdshn(n)
      implicit none
      integer n
      write(agdshn,'(a,i0,a)') 'DASH/PATTERN/', n, '.'
      return
      end function agdshn

! Axis ranges from the data (nice ends at major ticks) and the SET call
! of the grid window
      subroutine agstup(xdra,nvix,iivx,nevx,iiex, &
     &  ydra,nviy,iivy,nevy,iiey)
      use autograph_py
      implicit none
      integer nvix, iivx, nevx, iiex, nviy, iivy, nevy, iiey
      real xdra(*), ydra(*)
      real xmin, xmax, ymin, ymax
      external set
      call agpy_range(xdra,nvix,iivx,nevx,iiex,xmin,xmax)
      call agpy_range(ydra,nviy,iivy,nevy,iiey,ymin,ymax)
      call agpy_nice(xmin,xmax,xlog,majcnt(1),set_w(1),set_w(2), &
     &  nmajor(1),nminor(1))
      call agpy_nice(ymin,ymax,ylog,majcnt(2),set_w(3),set_w(4), &
     &  nmajor(2),nminor(2))
      set_v = (/ grid_l, grid_r, grid_b, grid_t /)
      set_lf = 1+2*min(xlog,1)+min(ylog,1)
      call set(set_v(1),set_v(2),set_v(3),set_v(4), &
     &  set_w(1),set_w(2),set_w(3),set_w(4),set_lf)
      return
      end subroutine agstup

! Range of the values of an AGSTUP array (1.E36 are missing values)
      subroutine agpy_range(dra,nvi,iiv,nev,iie,dmin,dmax)
      implicit none
      integer nvi, iiv, nev, iie
      real dra(*), dmin, dmax
      integer i, j, k
      real v
      dmin = huge(dmin)
      dmax = -huge(dmax)
      do i = 1, max(nvi,1)
        do j = 1, nev
          if (iie.eq.0) then
            v = real(j)
          else
            k = 1+(i-1)*iiv+(j-1)*iie
            v = dra(k)
          end if
          if (abs(v).ge.1.e35) cycle
          dmin = min(dmin,v)
          dmax = max(dmax,v)
        end do
      end do
      if (dmax.lt.dmin) then
        dmin = 0.
        dmax = 1.
      end if
      return
      end subroutine agpy_range

! The background: grid perimeter with ticks and numeric labels, labels
! T, B and L
      subroutine agback
      use autograph_py
      implicit none
      real side, nw, cw, gap, x, y, v
      integer isz(2), il, i, nl
      character*256 line
      character*16 fmt, num
      external set, labmod, gridal, tick4, plchhq, agchax, agchil
      side = min(set_v(2)-set_v(1),set_v(4)-set_v(3))
      do i = 1, 2
        isz(i) = max(4,nint(numwid(i)*side*1024.*gkssiz))
      end do
      gap = 0.015*side
      call set(set_v(1),set_v(2),set_v(3),set_v(4), &
     &  set_w(1),set_w(2),set_w(3),set_w(4),set_lf)
      call agchax(0,1,1,0.)
      call tick4(nint(gap*1024.),nint(gap*683.), &
     &  nint(gap*1024.),nint(gap*683.))
      call labmod(agpy_format(1),agpy_format(2),0,0,isz(1),isz(2), &
     &  nint(gap*1024.),nint(gap*1024.),0)
      call gridal(nmajor(1),nminor(1),nmajor(2),nminor(2),1,1,5,0.,0.)
      call agchax(1,1,1,0.)
! Length of the longest numeric label of the left axis
      fmt = agpy_format(2)
      nl = 5
      if (ylog.eq.0) then
        nl = 1
        do i = 0, nmajor(2)
          v = set_w(3)+(set_w(4)-set_w(3))*real(i)/real(nmajor(2))
          if (fmt(2:2).eq.'i') then
            write(num,fmt) nint(v)
          else
            write(num,fmt) v
          end if
          nl = max(nl,len_trim(adjustl(num)))
        end do
      end if
! Labels in fractions of the frame
      call set(0.,1.,0.,1.,0.,1.,0.,1.,1)
      do il = 1, 3
        line = agpy_text(lbtext(il))
        if (len_trim(line).eq.0) cycle
        cw = lbwid(il)*side
! Outside the grid window, inside the frame
        if (il.eq.1) then
          x = 0.5*(set_v(1)+set_v(2))
          y = min(set_v(4)+gap+cw,1.-0.8*cw)
        else if (il.eq.2) then
          nw = numwid(1)*side
          x = 0.5*(set_v(1)+set_v(2))
          y = max(set_v(3)-2.*gap-1.6*nw-cw,0.8*cw)
        else
          nw = numwid(2)*side
          x = max(set_v(1)-2.*gap-real(nl)*nw-0.8*cw,0.8*cw)
          y = 0.5*(set_v(3)+set_v(4))
        end if
        call agchil(0,'TBL'(il:il),1)
        call plchhq(x,y,trim(line),cw*gkssiz,lbang(il),0.)
        call agchil(1,'TBL'(il:il),1)
      end do
      call set(set_v(1),set_v(2),set_v(3),set_v(4), &
     &  set_w(1),set_w(2),set_w(3),set_w(4),set_lf)
      return
      end subroutine agback

! A curve in the user coordinates of the last AGSTUP, with the dash
! pattern selected by KDSH (solid for 0); 1.E36 values break the curve
      subroutine agcurv(xvec,iiex,yvec,iiey,nexy,kdsh)
      use autograph_py
      implicit none
      integer iiex, iiey, nexy, kdsh
      real xvec(*), yvec(*)
      real x(max(nexy,1)), y(max(nexy,1)), side
      integer i, k, m, jcrt
      character*64 pat
      external dashdc, curved, agchcu
      call agchcu(0,kdsh)
      pat = '$$$$$$$$$$$$$$$$'
      if (kdsh.ne.0.and.ndsh.gt.0) then
        k = mod(abs(kdsh)-1,ndsh)+1
        if (len_trim(dshpat(k)).gt.0) pat = dshpat(k)
      end if
      side = min(set_v(2)-set_v(1),set_v(4)-set_v(3))
      jcrt = max(1,nint(0.5*dshchr*side*1024.))
      call dashdc(trim(pat),jcrt,2*jcrt)
      m = 0
      do i = 1, nexy
        if (iiex.eq.0) then
          x(m+1) = real(i)
        else
          x(m+1) = xvec(1+(i-1)*iiex)
        end if
        if (iiey.eq.0) then
          y(m+1) = real(i)
        else
          y(m+1) = yvec(1+(i-1)*iiey)
        end if
        if (abs(x(m+1)).ge.1.e35.or.abs(y(m+1)).ge.1.e35) then
          if (m.gt.1) call curved(x,y,m)
          m = 0
        else
          m = m+1
        end if
      end do
      if (m.gt.1) call curved(x,y,m)
      call agchcu(1,kdsh)
      return
      end subroutine agcurv

! The SET call of the last AGSTUP
      subroutine getset(vl,vr,vb,vt,wl,wr,wb,wt,lf)
      use autograph_py
      implicit none
      real vl, vr, vb, vt, wl, wr, wb, wt
      integer lf
      vl = set_v(1)
      vr = set_v(2)
      vb = set_v(3)
      vt = set_v(4)
      wl = set_w(1)
      wr = set_w(2)
      wb = set_w(3)
      wt = set_w(4)
      lf = set_lf
      return
      end subroutine getset

! Movie files of b2plot, none in Carre2
      subroutine mvf_close
      implicit none
      return
      end subroutine mvf_close
